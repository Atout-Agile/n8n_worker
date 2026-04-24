# frozen_string_literal: true

# Creates or updates a personal notification channel for the current user.
# The `type` argument must be one of: internal, ntfy, email, webhook.
# Shared channels are added via AddSharedChannelToMyChannels instead.
#
# @since 2026-04-11
module Mutations
  class UpsertNotificationChannel < BaseMutation
    permission_required "assistant_config:write"

    argument :id, ID, required: false
    argument :type, String, required: true
    argument :active, Boolean, required: false, default_value: true
    argument :config, GraphQL::Types::JSON, required: true

    field :notification_channel, Types::NotificationChannelType, null: true
    field :errors, [ String ], null: false

    # @param type [String]
    # @param active [Boolean]
    # @param config [Hash]
    # @param id [String, nil]
    # @return [Hash]
    def resolve(type:, active:, config:, id: nil)
      authorize! current_user, to: :write?, with: NotificationChannelPolicy

      if type == "shared"
        return { notification_channel: nil,
                 errors: [ "use addSharedChannelToMyChannels for shared channels" ] }
      end

      channel = id ? current_user.notification_channels.find_by(id: id) : current_user.notification_channels.build
      return { notification_channel: nil, errors: [ "not found" ] } if channel.nil?

      channel.channel_type = type
      channel.active = active
      channel.config = config

      if channel.save
        { notification_channel: channel, errors: [] }
      else
        { notification_channel: nil, errors: channel.errors.full_messages }
      end
    end
  end
end
