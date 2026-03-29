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

  # Replaces the role's permission set with the supplied IDs, cascading any
  # removals to API tokens.
  #
  # Unlike plain +permission_ids=+, this method computes an explicit diff and
  # removes permissions one-by-one via the association so that the
  # +after_remove+ callback fires for each — which revokes those permissions
  # from every token owned by users of this role.
  #
  # @param new_permission_ids [Array<Integer, String>] IDs of the desired permissions
  # @return [void]
  def assign_permissions(new_permission_ids)
    new_ids      = new_permission_ids.map(&:to_i).to_set
    current_ids  = permission_ids.to_set

    to_remove = permissions.where(id: (current_ids - new_ids).to_a).to_a
    to_add    = Permission.where(id: (new_ids - current_ids).to_a)

    permissions.delete(to_remove) if to_remove.any?
    permissions << to_add         if to_add.any?
  end

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
