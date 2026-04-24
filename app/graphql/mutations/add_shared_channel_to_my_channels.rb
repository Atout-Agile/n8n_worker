# frozen_string_literal: true

# Activates a previously-acknowledged shared channel.
# Returns an error if consent has not been recorded yet.
#
# @since 2026-04-11
module Mutations
  class AddSharedChannelToMyChannels < BaseMutation
    permission_required "assistant_config:write"

    argument :shared_channel_id, ID, required: true

    field :notification_channel, Types::NotificationChannelType, null: true
    field :errors, [ String ], null: false

    # @param shared_channel_id [String]
    # @return [Hash]
    def resolve(shared_channel_id:)
      authorize! current_user, to: :write?, with: NotificationChannelPolicy
      channel = current_user.notification_channels
                            .where(shared_notification_channel_id: shared_channel_id, channel_type: "shared")
                            .first
      if channel.nil? || channel.consent_acknowledged_at.blank?
        return { notification_channel: nil, errors: [ "consent must be acknowledged first" ] }
      end

      channel.update(active: true)
      { notification_channel: channel, errors: [] }
    end
  end
end
