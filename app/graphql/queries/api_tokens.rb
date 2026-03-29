# frozen_string_literal: true

# GraphQL query returning the authenticated user's active API tokens.
# Requires the +tokens:read+ permission.
#
# @example
#   query { apiTokens { id name active expiresAt lastUsedAt } }
#
# @see Types::ApiTokenType
# @see ApiTokenPolicy
# @since 2026-03-28
module Queries
  # Returns active API tokens belonging to the current user.
  #
  # @note Requires +tokens:read+ permission
  class ApiTokens < Queries::BaseQuery
    permission_required "tokens:read"

    type [Types::ApiTokenType], null: false

    # @return [Array<ApiToken>]
    # @raise [ActionPolicy::Unauthorized] if +tokens:read+ permission is missing
    def resolve
      authorize! current_user, to: :read?, with: ApiTokenPolicy

      current_user.api_tokens.active.order(created_at: :desc)
    end
  end
end
