# frozen_string_literal: true

class Role < ApplicationRecord
  # Associations
  has_many :users, dependent: :restrict_with_error
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions,
           after_remove: :revoke_token_permissions_for

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  private

  # Removes the given permission from every API token owned by users of this role.
  #
  # Called automatically via the +after_remove+ callback on the permissions association
  # whenever a permission is disassociated from this role, regardless of whether the
  # deletion went through ActiveRecord (+destroy+) or raw SQL (+delete_all+).
  #
  # @param permission [Permission] the permission that was removed from the role
  # @return [void]
  # @api private
  def revoke_token_permissions_for(permission)
    ApiTokenPermission
      .joins(api_token: :user)
      .where(users: { role_id: id }, permission_id: permission.id)
      .delete_all
  end
end
