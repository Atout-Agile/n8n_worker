# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    include ActionPolicy::GraphQL::Behaviour

    # Pass current_token to the policy authorization context
    authorize :token, through: :current_token

    argument_class Types::BaseArgument
    field_class Types::BaseField
    object_class Types::BaseObject

    # Declares the permission required to execute this mutation.
    # Used as a metadata annotation scanned by +rails permissions:sync+.
    #
    # @param permission [String] e.g. "tokens:write"
    # @return [void]
    def self.permission_required(permission)
      @required_permission = permission
    end

    # @return [String, nil] the declared required permission
    def self.required_permission
      @required_permission
    end

    # @return [User, nil]
    # @api private
    def current_user
      context[:current_user]
    end

    # @return [ApiToken, nil]
    # @api private
    def current_token
      context[:current_token]
    end
  end
end
