# frozen_string_literal: true

# Authorization policy for User resources.
#
# Governs access to user data and mutation operations.
# Delegates permission checks to +active_permissions+ from ApplicationPolicy.
#
# @example Usage in a GraphQL resolver
#   authorize! context[:current_user], to: :read?
#
# @see ApplicationPolicy
# @see Queries::User
# @see Queries::Users
# @see Mutations::UpdateUser
# @since 2026-03-28
class UserPolicy < ApplicationPolicy
  # @return [Boolean] true if the current context has +users:read+ permission
  def read?
    permission?("users:read")
  end

  # @return [Boolean] true if the current context has +users:write+ permission
  def write?
    permission?("users:write")
  end
end
