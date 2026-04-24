# frozen_string_literal: true

# Admin-only: updates an existing shared channel.
#
# @since 2026-04-11
module Mutations
  class UpdateSharedNotificationChannel < BaseMutation
    permission_required "assistant_shared_channels:write"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :channel_type, String, required: false
    argument :config, GraphQL::Types::JSON, required: false
    argument :active, Boolean, required: false

    field :shared_notification_channel, Types::SharedNotificationChannelType, null: true
    field :errors, [ String ], null: false

    # @param id [String]
    # @param attrs [Hash]
    # @return [Hash]
    def resolve(id:, **attrs)
      authorize! current_user, to: :write?, with: SharedNotificationChannelPolicy
      channel = SharedNotificationChannel.find_by(id: id)
      return { shared_notification_channel: nil, errors: [ "not found" ] } if channel.nil?

      channel.assign_attributes(attrs.compact)
      if channel.save
        { shared_notification_channel: channel, errors: [] }
      else
        { shared_notification_channel: nil, errors: channel.errors.full_messages }
      end
    end
  end
end
