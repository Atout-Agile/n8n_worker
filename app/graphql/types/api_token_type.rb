# frozen_string_literal: true

# GraphQL type definition for API tokens.
# Defines the structure and fields available when querying API tokens through GraphQL.
# This type represents the public interface for API token data.
#
# @example Querying an API token
#   {
#     apiToken {
#       id
#       name
#       expiresAt
#       active
#       user {
#         id
#         name
#       }
#     }
#   }
#
# @see Mutations::CreateApiToken
# @see ApiToken
# @since 2025-07-19
module Types
  # GraphQL type representing an API token
  #
  # @!attribute [r] id
  #   @return [ID] Unique identifier for the token
  # @!attribute [r] name
  #   @return [String] Descriptive name of the token
  # @!attribute [r] token
  #   @return [String, nil] The JWT token (only visible during creation for security)
  # @!attribute [r] expires_at
  #   @return [GraphQL::Types::ISO8601DateTime] When the token expires
  # @!attribute [r] last_used_at
  #   @return [GraphQL::Types::ISO8601DateTime, nil] When the token was last used
  # @!attribute [r] created_at
  #   @return [GraphQL::Types::ISO8601DateTime] When the token was created
  # @!attribute [r] updated_at
  #   @return [GraphQL::Types::ISO8601DateTime] When the token was last updated
  # @!attribute [r] user
  #   @return [Types::UserType] The user who owns this token
  # @!attribute [r] active
  #   @return [Boolean] Whether the token is still valid (not expired)
  class ApiTokenType < Types::BaseObject
    # @return [ID] The unique identifier
    field :id, ID, null: false
    
    # @return [String] The descriptive name
    field :name, String, null: false
    
    # @return [String, nil] The JWT token (only visible during creation)
    field :token, String, null: true, description: "The JWT token (only visible during creation)"
    
    # @return [GraphQL::Types::ISO8601DateTime] Token expiration timestamp
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # @return [GraphQL::Types::ISO8601DateTime, nil] Last usage timestamp
    field :last_used_at, GraphQL::Types::ISO8601DateTime, null: true
    
    # @return [GraphQL::Types::ISO8601DateTime] Creation timestamp
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # @return [GraphQL::Types::ISO8601DateTime] Last update timestamp
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # @return [Types::UserType] The token owner
    field :user, Types::UserType, null: false
    
    # @return [Boolean] Whether the token has not yet expired
    field :active, Boolean, null: false, description: "Indicates if the token has not yet expired"

    # Determines if the token is still active (not expired)
    #
    # @return [Boolean] true if token is still valid, false if expired
    def active
      object.expires_at > Time.current
    end
  end
end 