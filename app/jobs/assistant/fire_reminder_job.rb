# frozen_string_literal: true

module Assistant
  # Fires a single reminder at its planned time by delegating to
  # Assistant::AlertEmitter. Solid Queue handles retry-on-failure
  # with polynomially-longer backoff for transient exceptions.
  #
  # @see Assistant::AlertEmitter
  # @since 2026-04-11
  class FireReminderJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    # @param reminder_id [Integer]
    # @return [void]
    def perform(reminder_id)
      reminder = CalendarReminder.find_by(id: reminder_id)
      return if reminder.nil?

      AlertEmitter.new.emit(reminder: reminder)
    end
  end
end
