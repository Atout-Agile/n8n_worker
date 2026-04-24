# frozen_string_literal: true

module Assistant
  # Orchestrates the emission of a single reminder:
  # - verifies the reminder is still pending
  # - verifies we are still within the retry grace window
  # - resolves the user's active channels
  # - fans out via the channel Registry
  # - logs per-channel attempts in an AlertEmission row
  # - marks the reminder as emitted or expired accordingly
  #
  # Per-channel retries on failure are handled by the outer
  # FireReminderJob's Solid Queue retry mechanism; this emitter
  # performs one pass per call.
  #
  # @see Assistant::Channels::Registry
  # @see CalendarReminder
  # @see AlertEmission
  # @since 2026-04-11
  class AlertEmitter
    # @param settings [Assistant::Settings]
    # @param registry [Module] must respond to `.adapter_for(channel)`
    def initialize(settings: Assistant::Settings.current, registry: Assistant::Channels::Registry)
      @settings = settings
      @registry = registry
    end

    # Emits a reminder to all active channels for the reminder's user.
    #
    # Skips silently when the reminder is no longer pending. Marks the
    # reminder as expired if the event start time plus the grace window
    # has already passed. Otherwise creates an AlertEmission row, fans
    # out to every active channel, and marks the reminder as emitted.
    #
    # @param reminder [CalendarReminder]
    # @return [void]
    def emit(reminder:)
      return unless reminder.state == "pending"

      event = reminder.calendar_event
      if past_grace_window?(event)
        reminder.mark_expired!
        return
      end

      emission = create_emission(reminder)
      content = AlertContent.from_reminder_snapshot(
        reminder.content_snapshot,
        offset_minutes: reminder.offset_minutes
      )
      active_channels = reminder.calendar_event.user.notification_channels.where(active: true)

      if active_channels.empty?
        emission.record_channel_attempt("none", status: "no_channel")
      else
        fan_out(active_channels, content, reminder, emission)
      end

      reminder.mark_emitted!
    end

    private

    attr_reader :settings, :registry

    # @param event [CalendarEvent]
    # @return [Boolean]
    def past_grace_window?(event)
      Time.current > (event.starts_at + settings.retry_grace_seconds.seconds)
    end

    # @param reminder [CalendarReminder]
    # @return [AlertEmission]
    def create_emission(reminder)
      AlertEmission.create!(
        user: reminder.calendar_event.user,
        calendar_reminder: reminder,
        content_snapshot: reminder.content_snapshot,
        emitted_at: Time.current,
        channel_attempts: []
      )
    end

    # @param channels [ActiveRecord::Relation]
    # @param content [AlertContent]
    # @param reminder [CalendarReminder]
    # @param emission [AlertEmission]
    # @return [void]
    def fan_out(channels, content, reminder, emission)
      channels.find_each do |channel|
        next if channel.channel_type == "internal"

        emit_on_channel(channel, content, reminder, emission)
      end

      return unless channels.exists?(channel_type: "internal")

      emission.record_channel_attempt("internal", status: "success")
    end

    # @param channel [NotificationChannel]
    # @param content [AlertContent]
    # @param reminder [CalendarReminder]
    # @param emission [AlertEmission]
    # @return [void]
    def emit_on_channel(channel, content, reminder, emission)
      adapter = registry.adapter_for(channel)
      result = adapter.emit(content: content, reminder: reminder)
      emission.record_channel_attempt(
        channel.channel_type,
        status: result.success? ? "success" : "failed",
        error: result.error
      )
    rescue StandardError => e
      emission.record_channel_attempt(channel.channel_type, status: "failed", error: e.message)
    end
  end
end
