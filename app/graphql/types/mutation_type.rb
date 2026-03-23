# frozen_string_literal: true

# GraphQL root mutation type defining all available mutations.
# This type serves as the entry point for all write operations in the GraphQL API.
#
# @example Available mutations
#   mutation {
#     login(email: "user@example.com", password: "password") {
#       user { id name }
#       errors
#     }
#     
#     createApiToken(name: "My Token", expiresInDays: 30) {
#       apiToken { id name token }
#       errors  
#     }
#   }
#
# @see Mutations::Login
# @see Mutations::CreateApiToken
# @see Mutations::RevokeApiToken
# @since Initial version
module Types
  # Root mutation type for GraphQL schema
  #
  # @!attribute [r] login
  #   @return [Mutations::Login] User authentication mutation
  # @!attribute [r] create_api_token
  #   @return [Mutations::CreateApiToken] API token creation mutation (added 2025-07-19)
  # @!attribute [r] revoke_api_token
  #   @return [Mutations::RevokeApiToken] API token revocation mutation (added 2026-03-23)
  class MutationType < Types::BaseObject
    # User login mutation
    field :login, mutation: Mutations::Login

    # API token creation mutation
    # @since 2025-07-19
    field :create_api_token, mutation: Mutations::CreateApiToken

    # API token revocation mutation
    # @since 2026-03-23
    field :revoke_api_token, mutation: Mutations::RevokeApiToken
  end
end
