# frozen_string_literal: true

# GraphQL query returning all users.
# Requires the +users:read+ permission.
#
# @example
#   query { users { id email username role { name } } }
#
# @see Types::UserType
# @see UserPolicy
# @since 2026-03-28
module Queries
  # Returns all users ordered by name.
  #
  # @note Requires +users:read+ permission
  class Users < Queries::BaseQuery
    permission_required "users:read"

    type [Types::UserType], null: false

    # @return [Array<User>]
    # @raise [ActionPolicy::Unauthorized] if +users:read+ permission is missing
    def resolve
      authorize! current_user, to: :read?, with: UserPolicy

      ::User.order(:name)
    end
  end
end
