# frozen_string_literal: true

# Deletes one of the current user's notification channels.
#
# @since 2026-04-11
module Mutations
  class DeleteNotificationChannel < BaseMutation
    permission_required "assistant_config:write"

    argument :id, ID, required: true

    field :deleted_id, ID, null: true
    field :errors, [ String ], null: false

    # @param id [String]
    # @return [Hash]
    def resolve(id:)
      authorize! current_user, to: :write?, with: NotificationChannelPolicy
      channel = current_user.notification_channels.find_by(id: id)
      return { deleted_id: nil, errors: [ "not found" ] } if channel.nil?

      channel.destroy!
      { deleted_id: id, errors: [] }
    end
  end
end
