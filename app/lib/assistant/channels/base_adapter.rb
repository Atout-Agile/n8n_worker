# frozen_string_literal: true

module Assistant
  module Channels
    # Abstract base for notification channel adapters. Each concrete
    # adapter renders an {Assistant::AlertContent} into its channel's
    # native format and returns a {Result} object.
    #
    # @see Assistant::AlertEmitter
    # @since 2026-04-11
    class BaseAdapter
      Result = Struct.new(:status, :error, keyword_init: true) do
        def success?
          status == :success
        end
      end

      # @param channel [NotificationChannel] the channel record this adapter
      #   will deliver through
      def initialize(channel:)
        @channel = channel
      end

      # Deliver an alert through the concrete channel implementation.
      #
      # @param content [Assistant::AlertContent] the structured alert payload
      # @param reminder [CalendarReminder] the triggering reminder record
      # @return [Result]
      # @note reminder is provided for adapters that need to record provenance;
      #   implementations that do not use it should suppress the warning with _ = reminder
      def emit(content:, reminder:)
        raise NotImplementedError
      end

      protected

      attr_reader :channel
    end
  end
end
