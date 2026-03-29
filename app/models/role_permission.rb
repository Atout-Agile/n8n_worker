# frozen_string_literal: true

# Join model between Role and Permission.
#
# Uniqueness is enforced at the database level via a unique index on
# (role_id, permission_id). The cascade that revokes token permissions when a
# permission is removed from a role is handled by the +after_remove+ callback
# defined on {Role#permissions}, so it fires regardless of whether the deletion
# uses ActiveRecord or raw SQL.
#
# @see Role
# @see Permission
# @see ApiTokenPermission
class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  validates :permission_id, uniqueness: { scope: :role_id }
end
