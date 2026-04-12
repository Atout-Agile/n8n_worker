# frozen_string_literal: true

# Admin-only: creates a new shared notification channel.
#
# @since 2026-04-11
module Mutations
  class CreateSharedNotificationChannel < BaseMutation
    permission_required "assistant_shared_channels:write"

    argument :name, String, required: true
    argument :channel_type, String, required: true
    argument :config, GraphQL::Types::JSON, required: true
    argument :active, Boolean, required: false, default_value: true

    field :shared_notification_channel, Types::SharedNotificationChannelType, null: true
    field :errors, [ String ], null: false

    # @param name [String]
    # @param channel_type [String]
    # @param config [Hash]
    # @param active [Boolean]
    # @return [Hash]
    def resolve(name:, channel_type:, config:, active:)
      authorize! current_user, to: :write?, with: SharedNotificationChannelPolicy
      channel = SharedNotificationChannel.new(name: name, channel_type: channel_type, config: config, active: active)
      if channel.save
        { shared_notification_channel: channel, errors: [] }
      else
        { shared_notification_channel: nil, errors: channel.errors.full_messages }
      end
    end
  end
end
