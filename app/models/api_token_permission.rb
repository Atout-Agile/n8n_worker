# frozen_string_literal: true

# Join model between ApiToken and Permission.
#
# @see ApiToken
# @see Permission
class ApiTokenPermission < ApplicationRecord
  belongs_to :api_token
  belongs_to :permission

  validates :permission_id, uniqueness: { scope: :api_token_id }
end
