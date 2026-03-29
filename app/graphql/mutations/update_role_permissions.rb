# frozen_string_literal: true

# GraphQL mutation to update the permissions assigned to a role.
# Requires the +roles:write+ permission.
# Deprecated permissions are silently ignored.
#
# @example
#   mutation {
#     updateRolePermissions(roleId: "1", permissionIds: ["1", "2", "3"]) {
#       role { id name permissions { name } }
#       errors
#     }
#   }
#
# @see Types::RoleType
# @see RolePolicy
# @since 2026-03-29
module Mutations
  # Updates the permission set of a role.
  #
  # @note Requires +roles:write+ permission
  # @note Deprecated permission IDs are silently ignored
  class UpdateRolePermissions < BaseMutation
    permission_required "roles:write"

    # @!attribute [r] role_id
    #   @return [ID] ID of the role to update
    argument :role_id, ID, required: true, description: "ID of the role to update"

    # @!attribute [r] permission_ids
    #   @return [Array<ID>] New permission IDs to assign
    argument :permission_ids, [ID], required: true,
             description: "IDs of non-deprecated permissions to assign to the role"

    # @!attribute [r] role
    #   @return [Types::RoleType, nil] Updated role
    field :role, Types::RoleType, null: true

    # @!attribute [r] errors
    #   @return [Array<String>] Validation errors
    field :errors, [String], null: false

    # @param role_id [ID]
    # @param permission_ids [Array<ID>]
    # @return [Hash]
    # @raise [ActionPolicy::Unauthorized] if +roles:write+ permission is missing
    def resolve(role_id:, permission_ids:)
      authorize! current_user, to: :write?, with: RolePolicy

      role = ::Role.find_by(id: role_id)
      return { role: nil, errors: ["Role not found"] } unless role

      active_ids = Permission.where(id: permission_ids, deprecated: false).pluck(:id)
      role.permission_ids = active_ids

      if role.save
        { role: role, errors: [] }
      else
        { role: nil, errors: role.errors.full_messages }
      end
    end
  end
end
