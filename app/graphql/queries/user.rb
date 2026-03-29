# frozen_string_literal: true

# GraphQL query to fetch a single user by ID or email.
# Requires the +users:read+ permission.
#
# @example Query by ID
#   query { user(id: "1") { id email username role { name } } }
#
# @example Query by email
#   query { user(email: "admin@example.com") { id email username } }
#
# @see Types::UserType
# @see UserPolicy
# @since Initial version
module Queries
  # Returns a single user matching the given ID or email.
  #
  # @note Requires +users:read+ permission
  class User < Queries::BaseQuery
    permission_required "users:read"

    argument :id, ID, required: false
    argument :email, String, required: false

    type Types::UserType, null: true

    # @param id [ID, nil]
    # @param email [String, nil]
    # @return [User, nil]
    # @raise [ActionPolicy::Unauthorized] if +users:read+ permission is missing
    def resolve(id: nil, email: nil)
      authorize! current_user, to: :read?, with: UserPolicy

      return nil if id.nil? && email.nil?

      if id
        ::User.find_by(id: id)
      else
        ::User.find_by(email: email)
      end
    end
  end
end
