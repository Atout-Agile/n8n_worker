# frozen_string_literal: true

# GraphQL mutation to update the permissions assigned to an existing API token.
# Requires the +tokens:write+ permission.
# Only permissions belonging to the current user's role (non-deprecated) are accepted.
#
# @example
#   mutation {
#     updateApiTokenPermissions(id: "1", permissionIds: ["3", "4"]) {
#       apiToken { id name permissions { name } }
#       errors
#     }
#   }
#
# @see Types::ApiTokenType
# @see ApiTokenPolicy
# @since 2026-03-29
module Mutations
  # Updates the permission set of an API token owned by the authenticated user.
  #
  # @note Requires +tokens:write+ permission
  # @note Permission IDs outside the user's role are silently ignored
  class UpdateApiTokenPermissions < BaseMutation
    permission_required "tokens:write"

    # @!attribute [r] id
    #   @return [ID] ID of the token to update
    argument :id, ID, required: true, description: "ID of the API token to update"

    # @!attribute [r] permission_ids
    #   @return [Array<ID>] New permission IDs (must be a subset of the user's role permissions)
    argument :permission_ids, [ID], required: true,
             description: "IDs of permissions to grant (must be a subset of your role's permissions)"

    # @!attribute [r] api_token
    #   @return [Types::ApiTokenType, nil] Updated API token
    field :api_token, Types::ApiTokenType, null: true

    # @!attribute [r] errors
    #   @return [Array<String>] Validation errors
    field :errors, [String], null: false

    # @param id [ID]
    # @param permission_ids [Array<ID>]
    # @return [Hash]
    # @raise [ActionPolicy::Unauthorized] if +tokens:write+ permission is missing
    def resolve(id:, permission_ids:)
      authorize! current_user, to: :write?, with: ApiTokenPolicy

      api_token = current_user.api_tokens.find_by(id: id)
      return { api_token: nil, errors: ["Token not found"] } unless api_token

      allowed_ids = current_user.assignable_permissions.pluck(:id).to_set
      api_token.permission_ids = permission_ids.map(&:to_i).select { |pid| allowed_ids.include?(pid) }

      if api_token.save
        { api_token: api_token, errors: [] }
      else
        { api_token: nil, errors: api_token.errors.full_messages }
      end
    end
  end
end
