# frozen_string_literal: true

# GraphQL mutation to create API tokens for authenticated users.
# This mutation allows users to generate secure API tokens that can be used
# for programmatic access to the application's API endpoints.
#
# @example Creating a token with default expiration (30 days)
#   mutation {
#     createApiToken(name: "My Integration Token") {
#       apiToken {
#         id
#         name
#         token
#         expiresAt
#         active
#       }
#       errors
#     }
#   }
#
# @example Creating a token with custom expiration
#   mutation {
#     createApiToken(name: "Short Term Token", expiresInDays: 7) {
#       apiToken {
#         id
#         name
#         token
#         expiresAt
#         active
#       }
#       errors
#     }
#   }
#
# @see Types::ApiTokenType
# @see ApiToken
# @since 2025-07-19
module Mutations
  # Creates a new API token for the authenticated user
  #
  # @!method resolve(name:, expires_in_days:)
  #   Creates a secure API token with the specified name and expiration
  #   @param name [String] Descriptive name for the token (required)
  #   @param expires_in_days [Integer] Number of days until expiration (default: 30)
  #   @return [Hash] Hash containing :api_token and :errors
  #     - :api_token [ApiToken, nil] The created token (with raw token visible) or nil if failed
  #     - :errors [Array<String>] Array of error messages, empty if successful
  #
  # @note The raw token value is only visible during creation for security purposes
  # @note Requires user authentication through GraphQL context
  class CreateApiToken < GraphQL::Schema::Mutation
    # @!attribute [r] name
    #   @return [String] Descriptive name for the API token
    argument :name, String, required: true, description: "Descriptive name for the token"
    
    # @!attribute [r] expires_in_days
    #   @return [Integer] Number of days until token expiration
    argument :expires_in_days, Integer, required: false, default_value: 30, description: "Number of days until expiration (default: 30)"

    # @!attribute [r] api_token
    #   @return [Types::ApiTokenType, nil] The created API token
    field :api_token, Types::ApiTokenType, null: true
    
    # @!attribute [r] errors
    #   @return [Array<String>] Array of validation or creation errors
    field :errors, [String], null: false

    # Resolves the mutation by creating a new API token
    #
    # @param name [String] The descriptive name for the token
    # @param expires_in_days [Integer] Number of days until expiration
    # @return [Hash] Result hash with api_token and errors
    # @raise [SecurityError] If user is not authenticated
    def resolve(name:, expires_in_days:)
      # Verify user authentication
      current_user = context[:current_user]
      
      if current_user.nil?
        return {
          api_token: nil,
          errors: ['You must be logged in to create an API token']
        }
      end

      # Create the API token
      expires_at = expires_in_days.days.from_now
      raw_token = SecureRandom.hex(32)
      
      api_token = ApiToken.new(
        name: name,
        user: current_user,
        token_digest: Digest::SHA256.hexdigest(raw_token),
        expires_at: expires_at
      )

      if api_token.save
        # Add the raw token to the object for return (visible only at creation)
        api_token.define_singleton_method(:token) { raw_token }
        
        {
          api_token: api_token,
          errors: []
        }
      else
        {
          api_token: nil,
          errors: api_token.errors.full_messages
        }
      end
    end
  end
end 