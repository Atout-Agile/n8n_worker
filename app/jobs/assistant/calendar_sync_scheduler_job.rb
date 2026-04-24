# frozen_string_literal: true

module Assistant
  # Recurring scheduler: enqueues one PerUserCalendarSyncJob per user
  # with a configured calendar source. Invoked by Solid Queue's
  # recurring jobs system at the cadence configured in
  # `config/recurring.yml`.
  #
  # @see Assistant::PerUserCalendarSyncJob
  # @see Assistant::Settings
  # @since 2026-04-11
  class CalendarSyncSchedulerJob < ApplicationJob
    queue_as :default

    # @return [void]
    def perform
      UserAssistantConfig.where.not(calendar_source_url: [ nil, "" ]).find_each do |config|
        PerUserCalendarSyncJob.perform_later(config.user_id)
      end
    end
  end
end
