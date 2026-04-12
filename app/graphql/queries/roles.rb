# frozen_string_literal: true

# GraphQL query to list all roles with their assigned permissions.
# Requires the +roles:read+ permission.
#
# @example
#   query {
#     roles {
#       id name description
#       permissions { id name }
#     }
#   }
#
# @see Types::RoleType
# @see RolePolicy
# @since 2026-03-29
module Queries
  # Returns all roles ordered by name.
  #
  # @note Requires +roles:read+ permission
  class Roles < BaseQuery
    permission_required "roles:read"

    type [ Types::RoleType ], null: false

    # @return [ActiveRecord::Relation<Role>]
    # @raise [ActionPolicy::Unauthorized] if +roles:read+ permission is missing
    def resolve
      authorize! current_user, to: :read?, with: RolePolicy
      ::Role.includes(:permissions).order(:name)
    end
  end
end
