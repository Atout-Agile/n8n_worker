# frozen_string_literal: true

# GraphQL query to verify the validity of an API token.
# Accepts a raw token string, hashes it, and looks up the corresponding ApiToken.
# Returns the token details if valid and active, or nil if not found or expired.
# Intended for use by external services (e.g. n8n) to validate tokens before making API calls.
#
# @example Verifying a token
#   query {
#     verifyToken(token: "<raw_token>") {
#       id
#       name
#       active
#       expiresAt
#       lastUsedAt
#       user {
#         id
#         email
#       }
#     }
#   }
#
# @see ApiToken
# @see Types::ApiTokenType
# @since 2026-03-23
module Queries
  # Verifies an API token and returns its details if valid and active
  #
  # @!method resolve(token:)
  #   @param token [String] The raw API token to verify
  #   @return [ApiToken, nil] The active token record, or nil if not found or expired
  class VerifyToken < Queries::BaseQuery
    # @!attribute [r] token
    #   @return [String] The raw API token to verify
    argument :token, String, required: true, description: "The raw API token to verify"

    type Types::ApiTokenType, null: true

    # Resolves the query by looking up and validating the token
    #
    # @param token [String] The raw token value
    # @return [ApiToken, nil] Active token record, or nil if invalid or expired
    def resolve(token:)
      api_token = ApiToken.find_by_token(token)
      api_token&.active? ? api_token : nil
    end
  end
end
