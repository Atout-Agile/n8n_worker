# frozen_string_literal: true

module Queries
  class BaseQuery < GraphQL::Schema::Resolver
    include ActionPolicy::GraphQL::Behaviour

    # Pass current_token to the policy authorization context
    authorize :token, through: :current_token

    # Declares the permission required to execute this query.
    # Used as a metadata annotation scanned by +rails permissions:sync+.
    #
    # @param permission [String] e.g. "users:read"
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
