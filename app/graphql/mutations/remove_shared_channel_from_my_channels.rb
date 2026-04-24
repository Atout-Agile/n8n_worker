# frozen_string_literal: true

# Removes a shared channel from the user's active channels.
# Destroys the personal record; re-adding requires a fresh consent.
#
# @since 2026-04-11
module Mutations
  class RemoveSharedChannelFromMyChannels < BaseMutation
    permission_required "assistant_config:write"

    argument :shared_channel_id, ID, required: true

    field :removed, Boolean, null: false
    field :errors, [ String ], null: false

    # @param shared_channel_id [String]
    # @return [Hash]
    def resolve(shared_channel_id:)
      authorize! current_user, to: :write?, with: NotificationChannelPolicy
      channel = current_user.notification_channels
                            .where(shared_notification_channel_id: shared_channel_id, channel_type: "shared")
                            .first
      return { removed: false, errors: [ "not found" ] } if channel.nil?

      channel.destroy!
      { removed: true, errors: [] }
    end
  end
end
