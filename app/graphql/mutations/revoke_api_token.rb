# frozen_string_literal: true

# GraphQL mutation to revoke an API token for the authenticated user.
# Once revoked, the token can no longer be used for authentication.
# Requires the +tokens:write+ permission.
#
# @example Revoking a token by ID
#   mutation {
#     revokeApiToken(id: "42") {
#       success
#       errors
#     }
#   }
#
# @see Types::ApiTokenType
# @see ApiToken
# @see ApiTokenPolicy
# @since 2026-03-23
module Mutations
  # Revokes an existing API token belonging to the authenticated user.
  #
  # @note Requires +tokens:write+ permission
  # @note Users can only revoke their own tokens
  class RevokeApiToken < BaseMutation
    permission_required "tokens:write"

    # @!attribute [r] id
    #   @return [ID] The ID of the API token to revoke
    argument :id, ID, required: true, description: "ID of the token to revoke"

    # @!attribute [r] success
    #   @return [Boolean] Whether the revocation succeeded
    field :success, Boolean, null: false

    # @!attribute [r] errors
    #   @return [Array<String>] Array of validation or authorization errors
    field :errors, [String], null: false

    # @param id [ID] The ID of the token to revoke
    # @return [Hash] Result hash with success and errors
    # @raise [ActionPolicy::Unauthorized] if +tokens:write+ permission is missing
    def resolve(id:)
      authorize! current_user, to: :write?, with: ApiTokenPolicy

      api_token = current_user.api_tokens.find_by(id: id)
      return { success: false, errors: ['Token not found'] } if api_token.nil?

      if api_token.update(expires_at: Time.current)
        { success: true, errors: [] }
      else
        { success: false, errors: api_token.errors.full_messages }
      end
    end
  end
end
