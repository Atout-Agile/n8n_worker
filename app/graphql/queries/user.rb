# frozen_string_literal: true

module Queries
  class User < Queries::BaseQuery
    argument :id, ID, required: false
    argument :email, String, required: false

    type Types::UserType, null: true

    def resolve(id: nil, email: nil)
      return nil if id.nil? && email.nil?

      if id
        ::User.find_by(id: id)
      else
        ::User.find_by(email: email)
      end
    end
  end
end 