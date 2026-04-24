# frozen_string_literal: true

module Types
  class RoleType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: false
    field :permissions, [ Types::PermissionType ], null: false,
          description: "Non-deprecated permissions assigned to this role"

    def permissions
      object.permissions.reject(&:deprecated).sort_by(&:name)
    end
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
