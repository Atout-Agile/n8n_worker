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

      def initialize(channel:)
        @channel = channel
      end

      # @param content [Assistant::AlertContent]
      # @param reminder [CalendarReminder]
      # @return [Result]
      def emit(content:, reminder:)
        raise NotImplementedError
      end

      protected

      attr_reader :channel
    end
  end
end
