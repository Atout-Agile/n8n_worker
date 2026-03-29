# frozen_string_literal: true

# GraphQL query to verify the validity of an API token.
# Accepts a raw token string, hashes it, and looks up the corresponding ApiToken.
# Requires the +tokens:read+ permission.
#
# @example Verifying a token
#   query {
#     verifyToken(token: "<raw_token>") {
#       id name active expiresAt lastUsedAt user { id email }
#     }
#   }
#
# @see ApiToken
# @see Types::ApiTokenType
# @see ApiTokenPolicy
# @since 2026-03-23
module Queries
  # Verifies an API token and returns its details if valid and active.
  #
  # @note Requires +tokens:read+ permission
  class VerifyToken < Queries::BaseQuery
    permission_required "tokens:read"

    # @!attribute [r] token
    #   @return [String] The raw API token to verify
    argument :token, String, required: true, description: "The raw API token to verify"

    type Types::ApiTokenType, null: true

    # @param token [String] The raw token value
    # @return [ApiToken, nil] Active token record, or nil if invalid or expired
    # @raise [ActionPolicy::Unauthorized] if +tokens:read+ permission is missing
    def resolve(token:)
      authorize! current_user, to: :read?, with: ApiTokenPolicy

      api_token = ApiToken.find_by_token(token)
      api_token&.active? ? api_token : nil
    end
  end
end
