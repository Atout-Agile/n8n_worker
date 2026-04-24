# frozen_string_literal: true

module Assistant
  # Diffs the latest ParsedEvent list from a user's calendar source
  # against the stored CalendarEvent rows and applies the classification
  # rules from spec §2.2 and §2.3.
  #
  # @example
  #   Assistant::EventReconciler.new(user: user).reconcile(parsed_events)
  #
  # @see Assistant::IcsParser
  # @see Assistant::ReminderPlanner
  # @see CalendarEvent
  # @see CalendarReminder
  # @since 2026-04-11
  class EventReconciler
    Summary = Struct.new(:created, :updated, :touched, :disappeared, :soft_deleted, keyword_init: true) do
      def initialize(**args)
        super(**{ created: 0, updated: 0, touched: 0, disappeared: 0, soft_deleted: 0 }.merge(args))
      end
    end

    def initialize(user:, settings: Assistant::Settings.current, planner: Assistant::ReminderPlanner.new)
      @user = user
      @settings = settings
      @planner = planner
    end

    # @param parsed_events [Array<Assistant::ParsedEvent>]
    # @return [Summary]
    def reconcile(parsed_events)
      summary = Summary.new
      seen_uids = []

      parsed_events.each do |parsed|
        seen_uids << parsed.external_uid
        handle_parsed(parsed, summary)
      end

      handle_disappeared(seen_uids, summary)
      summary
    end

    private

    attr_reader :user, :settings, :planner

    def handle_parsed(parsed, summary)
      event = user.calendar_events.find_by(external_uid: parsed.external_uid)

      if event.nil?
        create_event_with_reminders(parsed, summary)
      else
        update_event(event, parsed, summary)
      end
    end

    def create_event_with_reminders(parsed, summary)
      event = user.calendar_events.create!(
        external_uid: parsed.external_uid,
        title: parsed.title,
        starts_at: parsed.starts_at,
        ends_at: parsed.ends_at,
        location: parsed.location,
        description: parsed.description,
        source_last_modified: parsed.source_last_modified,
        last_seen_at: Time.current,
        disappeared_tick_count: 0,
        raw_payload: parsed.raw_payload
      )
      planner.plan_reminders_for(event, user: user, intervals: user_intervals)
      summary.created += 1
    end

    def update_event(event, parsed, summary)
      event.update!(disappeared_tick_count: 0) if event.disappeared_tick_count.positive?
      event.update!(deleted_at: nil) if event.soft_deleted?

      if temporal_change?(event, parsed)
        event.calendar_reminders.pending.find_each(&:mark_invalidated!)
        event.update!(
          starts_at: parsed.starts_at,
          ends_at: parsed.ends_at,
          title: parsed.title,
          location: parsed.location,
          description: parsed.description,
          source_last_modified: parsed.source_last_modified,
          last_seen_at: Time.current,
          raw_payload: parsed.raw_payload
        )
        planner.plan_reminders_for(event, user: user, intervals: user_intervals)
        summary.updated += 1
      elsif non_temporal_change?(event, parsed)
        event.update!(
          title: parsed.title,
          location: parsed.location,
          description: parsed.description,
          source_last_modified: parsed.source_last_modified,
          last_seen_at: Time.current,
          raw_payload: parsed.raw_payload
        )
        summary.updated += 1
      else
        event.update!(last_seen_at: Time.current)
        summary.touched += 1
      end
    end

    def temporal_change?(event, parsed)
      event.starts_at != parsed.starts_at || event.ends_at != parsed.ends_at
    end

    def non_temporal_change?(event, parsed)
      event.title != parsed.title ||
        event.location != parsed.location ||
        event.description != parsed.description
    end

    def handle_disappeared(seen_uids, summary)
      scope = user.calendar_events.scheduled_scope
      scope = scope.where.not(external_uid: seen_uids) if seen_uids.any?

      scope.find_each do |event|
        new_count = event.disappeared_tick_count + 1
        if new_count >= settings.disappearance_grace_ticks
          event.update!(disappeared_tick_count: new_count, deleted_at: Time.current)
          event.calendar_reminders.pending.find_each(&:mark_invalidated!)
          summary.soft_deleted += 1
        else
          event.update!(disappeared_tick_count: new_count)
          summary.disappeared += 1
        end
      end
    end

    def user_intervals
      intervals = user.assistant_config&.reminder_intervals
      intervals.presence || settings.default_reminder_intervals
    end
  end
end
