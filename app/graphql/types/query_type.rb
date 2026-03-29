# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end

    field :user, resolver: Queries::User

    # @since 2026-03-28
    field :users, resolver: Queries::Users

    # @since 2026-03-23
    field :verify_token, resolver: Queries::VerifyToken

    # @since 2026-03-28
    field :api_tokens, resolver: Queries::ApiTokens

    # @since 2026-03-29
    field :roles, resolver: Queries::Roles

    # @since 2026-03-29
    field :permissions, resolver: Queries::Permissions
  end
end
