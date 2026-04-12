# frozen_string_literal: true

# Returns the current user's assistant config (lazily creating it on first access).
# Requires the +assistant_config:read+ permission.
#
# @example
#   query { assistantConfig { id timezone reminderIntervals } }
#
# @see Types::UserAssistantConfigType
# @see UserAssistantConfigPolicy
# @since 2026-04-11
module Queries
  class AssistantConfig < Queries::BaseQuery
    permission_required "assistant_config:read"

    type Types::UserAssistantConfigType, null: false

    # @return [UserAssistantConfig]
    # @raise [ActionPolicy::Unauthorized]
    def resolve
      authorize! current_user, to: :read?, with: UserAssistantConfigPolicy
      current_user.assistant_config || current_user.create_assistant_config!
    end
  end
end
