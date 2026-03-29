# frozen_string_literal: true

# GraphQL mutation to create API tokens for authenticated users.
# Requires the +tokens:write+ permission.
#
# @example Creating a token with default expiration (30 days)
#   mutation {
#     createApiToken(name: "My Integration Token") {
#       apiToken { id name token expiresAt active }
#       errors
#     }
#   }
#
# @example Creating a token with custom expiration
#   mutation {
#     createApiToken(name: "Short Term Token", expiresInDays: 7) {
#       apiToken { id name token expiresAt active }
#       errors
#     }
#   }
#
# @see Types::ApiTokenType
# @see ApiToken
# @see ApiTokenPolicy
# @since 2025-07-19
module Mutations
  # Creates a new API token for the authenticated user.
  #
  # @note Requires +tokens:write+ permission
  # @note The raw token value is only visible during creation for security purposes
  class CreateApiToken < BaseMutation
    permission_required "tokens:write"

    # @!attribute [r] name
    #   @return [String] Descriptive name for the API token
    argument :name, String, required: true, description: "Descriptive name for the token"

    # @!attribute [r] expires_in_days
    #   @return [Integer] Number of days until token expiration
    argument :expires_in_days, Integer, required: false,
             default_value: ApiToken::DEFAULT_EXPIRATION_DAYS,
             description: "Number of days until expiration (default: #{ApiToken::DEFAULT_EXPIRATION_DAYS})"

    # @!attribute [r] permission_ids
    #   @return [Array<ID>] Permissions to grant (must be a subset of the user's role permissions)
    argument :permission_ids, [ID], required: false, default_value: [],
             description: "IDs of permissions to grant (must be a subset of your role's permissions)"

    # @!attribute [r] api_token
    #   @return [Types::ApiTokenType, nil] The created API token
    field :api_token, Types::ApiTokenType, null: true

    # @!attribute [r] errors
    #   @return [Array<String>] Array of validation or creation errors
    field :errors, [String], null: false

    # @param name [String] The descriptive name for the token
    # @param expires_in_days [Integer] Number of days until expiration
    # @param permission_ids [Array<ID>] Permissions to assign (filtered to role scope)
    # @return [Hash] Result hash with api_token and errors
    # @raise [ActionPolicy::Unauthorized] if +tokens:write+ permission is missing
    def resolve(name:, expires_in_days:, permission_ids:)
      authorize! current_user, to: :write?, with: ApiTokenPolicy

      raw_token = SecureRandom.hex(32)
      api_token = ApiToken.new(
        name: name,
        user: current_user,
        token_digest: Digest::SHA256.hexdigest(raw_token),
        expires_at: expires_in_days.days.from_now
      )

      allowed_ids = current_user.assignable_permissions.map(&:id).to_set
      api_token.permission_ids = permission_ids.map(&:to_i).select { |id| allowed_ids.include?(id) }

      if api_token.save
        api_token.raw_token = raw_token
        { api_token: api_token, errors: [] }
      else
        { api_token: nil, errors: api_token.errors.full_messages }
      end
    end
  end
end
