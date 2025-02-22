# frozen_string_literal: true

module Mutations
  class Login < BaseMutation
    # Arguments
    argument :email, String, required: true
    argument :password, String, required: true

    # Fields
    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(email:, password:)
      user = User.find_by(email: email)

      if user&.authenticate(password)
        token = JWT::JsonWebToken.encode(
          user_id: user.id,
          email: user.email,
          role: user.role.name
        )

        {
          token: token,
          user: user,
          errors: []
        }
      else
        {
          token: nil,
          user: nil,
          errors: ["Email ou mot de passe invalide"]
        }
      end
    end
  end
end
