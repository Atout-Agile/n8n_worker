# frozen_string_literal: true

# GraphQL mutation to update user profile fields.
# Requires the +users:write+ permission.
#
# @example Updating a user's name
#   mutation {
#     updateUser(id: "1", name: "New Name") {
#       user { id email username }
#       errors
#     }
#   }
#
# @see Types::UserType
# @see UserPolicy
# @since 2026-03-28
module Mutations
  # Updates name and/or email for the specified user.
  #
  # @note Requires +users:write+ permission
  class UpdateUser < BaseMutation
    permission_required "users:write"

    # @!attribute [r] id
    #   @return [ID] ID of the user to update
    argument :id, ID, required: true, description: "ID of the user to update"

    # @!attribute [r] name
    #   @return [String, nil] New name (optional)
    argument :name, String, required: false, description: "New name"

    # @!attribute [r] email
    #   @return [String, nil] New email (optional)
    argument :email, String, required: false, description: "New email"

    # @!attribute [r] user
    #   @return [Types::UserType, nil] Updated user
    field :user, Types::UserType, null: true

    # @!attribute [r] errors
    #   @return [Array<String>] Validation errors
    field :errors, [String], null: false

    # @param id [ID]
    # @param name [String, nil]
    # @param email [String, nil]
    # @return [Hash] Result hash with user and errors
    # @raise [ActionPolicy::Unauthorized] if +users:write+ permission is missing
    def resolve(id:, name: nil, email: nil)
      authorize! current_user, to: :write?, with: UserPolicy

      user = ::User.find_by(id: id)
      return { user: nil, errors: ['User not found'] } unless user

      attrs = { name: name, email: email }.compact
      if user.update(attrs)
        { user: user, errors: [] }
      else
        { user: nil, errors: user.errors.full_messages }
      end
    end
  end
end
