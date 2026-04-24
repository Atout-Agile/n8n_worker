# frozen_string_literal: true

module Assistant
  module Channels
    # Writes the alert to the internal queue (the "channel A" from
    # spec §2.6) by creating an AlertEmission row.
    #
    # @see AlertEmission
    # @since 2026-04-11
    class InternalAdapter < BaseAdapter
      def emit(content:, reminder:)
        snapshot = reminder.content_snapshot.merge(
          "title" => content.title,
          "channel_type" => "internal"
        )
        AlertEmission.create!(
          user: channel.user,
          calendar_reminder: reminder,
          content_snapshot: snapshot,
          emitted_at: Time.current,
          channel_attempts: []
        )
        Result.new(status: :success)
      rescue StandardError => e
        Result.new(status: :failed, error: e.message)
      end
    end
  end
end
