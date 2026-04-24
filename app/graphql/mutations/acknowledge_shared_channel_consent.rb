# frozen_string_literal: true

# Records explicit informed-consent acknowledgment for a shared channel.
# Creates or updates a dormant (inactive) shared NotificationChannel row
# carrying the acknowledgment timestamp. A later
# AddSharedChannelToMyChannels flips it to active.
#
# @since 2026-04-11
module Mutations
  class AcknowledgeSharedChannelConsent < BaseMutation
    permission_required "assistant_config:write"

    argument :shared_channel_id, ID, required: true

    field :acknowledged_at, GraphQL::Types::ISO8601DateTime, null: true
    field :errors, [ String ], null: false

    # @param shared_channel_id [String]
    # @return [Hash]
    def resolve(shared_channel_id:)
      authorize! current_user, to: :write?, with: NotificationChannelPolicy
      shared = SharedNotificationChannel.find_by(id: shared_channel_id, active: true)
      return { acknowledged_at: nil, errors: [ "not found" ] } if shared.nil?

      channel = current_user.notification_channels
                            .where(shared_notification_channel: shared, channel_type: "shared")
                            .first_or_initialize
      channel.channel_type = "shared"
      channel.active = false if channel.new_record?
      channel.consent_acknowledged_at = Time.current
      channel.config = {}

      if channel.save
        { acknowledged_at: channel.consent_acknowledged_at, errors: [] }
      else
        { acknowledged_at: nil, errors: channel.errors.full_messages }
      end
    end
  end
end
