# frozen_string_literal: true

# Admin-only: deletes a shared channel. Fails if any personal
# notification_channels still reference it (model-level
# dependent: :restrict_with_error).
#
# @since 2026-04-11
module Mutations
  class DeleteSharedNotificationChannel < BaseMutation
    permission_required "assistant_shared_channels:write"

    argument :id, ID, required: true

    field :deleted_id, ID, null: true
    field :errors, [ String ], null: false

    # @param id [String]
    # @return [Hash]
    def resolve(id:)
      authorize! current_user, to: :write?, with: SharedNotificationChannelPolicy
      channel = SharedNotificationChannel.find_by(id: id)
      return { deleted_id: nil, errors: [ "not found" ] } if channel.nil?

      if channel.destroy
        { deleted_id: id, errors: [] }
      else
        { deleted_id: nil, errors: channel.errors.full_messages }
      end
    end
  end
end
