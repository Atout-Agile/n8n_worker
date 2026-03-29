# frozen_string_literal: true

# Authorization policy for ApiToken resources.
#
# Governs access to token listing, creation, and revocation operations.
# Delegates permission checks to +active_permissions+ from ApplicationPolicy.
#
# @example Usage in a GraphQL resolver
#   authorize! context[:current_user], to: :read?, with: ApiTokenPolicy
#
# @see ApplicationPolicy
# @see Queries::ApiTokens
# @see Queries::VerifyToken
# @see Mutations::CreateApiToken
# @see Mutations::RevokeApiToken
# @since 2026-03-28
class ApiTokenPolicy < ApplicationPolicy
  # @return [Boolean] true if the current context has +tokens:read+ permission
  def read?
    permission?("tokens:read")
  end

  # @return [Boolean] true if the current context has +tokens:write+ permission
  def write?
    permission?("tokens:write")
  end
end
