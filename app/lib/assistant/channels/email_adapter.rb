# frozen_string_literal: true

module Assistant
  module Channels
    # Dispatches alerts through AssistantMailer via deliver_later so
    # transient SMTP issues do not block the fan-out loop.
    #
    # @see AssistantMailer
    # @since 2026-04-11
    class EmailAdapter < BaseAdapter
      def emit(content:, reminder:)
        _ = reminder
        address = channel.config["address"]
        AssistantMailer.reminder_alert(
          address: address,
          title: content.title,
          time_until_start_label: content.time_until_start_label,
          starts_at: content.starts_at&.utc&.iso8601,
          ends_at: content.ends_at&.utc&.iso8601,
          location: content.location,
          description: content.description
        ).deliver_later
        Result.new(status: :success)
      rescue StandardError => e
        Result.new(status: :failed, error: e.message)
      end
    end
  end
end
