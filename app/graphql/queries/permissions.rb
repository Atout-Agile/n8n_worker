# frozen_string_literal: true

# GraphQL query to list all non-deprecated permissions.
# Requires the +roles:read+ permission.
#
# @example
#   query {
#     permissions { id name description }
#   }
#
# @see Types::PermissionType
# @see RolePolicy
# @since 2026-03-29
module Queries
  # Returns all active (non-deprecated) permissions ordered by name.
  #
  # @note Requires +roles:read+ permission
  class Permissions < BaseQuery
    permission_required "roles:read"

    type [Types::PermissionType], null: false

    # @return [ActiveRecord::Relation<Permission>]
    # @raise [ActionPolicy::Unauthorized] if +roles:read+ permission is missing
    def resolve
      authorize! current_user, to: :read?, with: RolePolicy
      ::Permission.where(deprecated: false).order(:name)
    end
  end
end
