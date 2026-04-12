# frozen_string_literal: true

module Assistant
  # Computes and persists the set of reminders for a calendar event,
  # applying the "late detection" rule (spec §2.3): a reminder whose
  # target time is already in the past at planning time is silently
  # dropped. Snapshots the event's content at planning time so that
  # the emitted alert reflects what was known when the reminder was
  # created (spec §2.5).
  #
  # @see CalendarEvent
  # @see CalendarReminder
  # @see Assistant::AlertContent
  # @since 2026-04-11
  class ReminderPlanner
    # @param event [CalendarEvent]
    # @param user [User] reserved for per-user customization hooks
    # @param intervals [Array<Integer>] offsets in minutes
    # @return [Array<CalendarReminder>] the reminders actually created
    def plan_reminders_for(event, user:, intervals:)
      _ = user
      created = []
      snapshot = build_snapshot(event)

      Array(intervals).each do |offset|
        fires_at = event.starts_at - offset.minutes
        next if fires_at <= Time.current

        reminder = event.calendar_reminders.create!(
          offset_minutes: offset,
          fires_at: fires_at,
          state: "pending",
          content_snapshot: snapshot
        )
        created << reminder
      end

      created
    end

    private

    def build_snapshot(event)
      {
        "event_id" => event.id,
        "external_uid" => event.external_uid,
        "title" => event.title,
        "location" => event.location,
        "description" => event.description,
        "starts_at" => event.starts_at.utc.iso8601,
        "ends_at" => event.ends_at.utc.iso8601
      }
    end
  end
end
