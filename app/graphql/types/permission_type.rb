# frozen_string_literal: true

# GraphQL type for a permission record.
#
# @example Querying permissions via a role
#   query {
#     user(id: "1") {
#       role {
#         permissions { id name description deprecated }
#       }
#     }
#   }
#
# @see Permission
# @since 2026-03-29
module Types
  # Represents a single permission that can be assigned to roles and API tokens.
  class PermissionType < Types::BaseObject
    # @return [ID]
    field :id, ID, null: false

    # @return [String] The permission name in resource:action format
    field :name, String, null: false, description: "Permission name in resource:action format (e.g. users:read)"

    # @return [String] Human-readable description
    field :description, String, null: false

    # @return [Boolean] Whether the permission has been deprecated
    field :deprecated, Boolean, null: false

    # @return [GraphQL::Types::ISO8601DateTime]
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
