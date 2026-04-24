# frozen_string_literal: true

# Lists active admin-provided shared notification channels.
# Requires the +assistant_shared_channels:read+ permission.
#
# @since 2026-04-11
module Queries
  class SharedNotificationChannels < Queries::BaseQuery
    permission_required "assistant_shared_channels:read"

    type [ Types::SharedNotificationChannelType ], null: false

    # @return [ActiveRecord::Relation]
    def resolve
      authorize! current_user, to: :read?, with: SharedNotificationChannelPolicy
      SharedNotificationChannel.where(active: true).order(:name)
    end
  end
end
