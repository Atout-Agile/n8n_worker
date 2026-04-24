# frozen_string_literal: true

module Assistant
  # Runs one synchronization pass for a single user's calendar source:
  # fetches the ICS feed, parses it, reconciles events, and enqueues
  # a FireReminderJob for each pending reminder at its planned fires_at.
  #
  # @see Assistant::IcsFetcher
  # @see Assistant::IcsParser
  # @see Assistant::EventReconciler
  # @see Assistant::FireReminderJob
  # @since 2026-04-11
  class PerUserCalendarSyncJob < ApplicationJob
    queue_as :default

    # @param user_id [Integer]
    # @return [void]
    def perform(user_id)
      user = User.find_by(id: user_id)
      return if user.nil?

      config = user.assistant_config
      return if config.nil? || !config.calendar_source_configured?

      result = IcsFetcher.new.fetch(config.calendar_source_url)
      if result.success?
        parsed = IcsParser.new.parse(result.body)
        EventReconciler.new(user: user).reconcile(parsed)
        enqueue_new_reminders(user)
        config.update!(last_polled_at: Time.current, last_poll_status: "success")
      else
        config.update!(last_polled_at: Time.current, last_poll_status: "failure: #{result.error}")
      end
    end

    private

    def enqueue_new_reminders(user)
      CalendarReminder
        .joins(:calendar_event)
        .where(calendar_events: { user_id: user.id })
        .where(state: "pending", solid_queue_job_key: nil)
        .find_each do |reminder|
        FireReminderJob.set(wait_until: [ reminder.fires_at, Time.current ].max).perform_later(reminder.id)
        reminder.update!(solid_queue_job_key: "enqueued-#{reminder.id}-#{Time.current.to_i}")
      end
    end
  end
end
