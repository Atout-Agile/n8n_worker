# frozen_string_literal: true

# Represents a permission that can be assigned to roles and API tokens.
# Permissions follow the format "resource:action" (e.g., "users:read").
#
# @see Role
# @see ApiToken
# @since 2026-03-28
class Permission < ApplicationRecord
  VALID_FORMAT = /\A[a-z_]+:(read|write)\z/

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  has_many :api_token_permissions, dependent: :destroy
  has_many :api_tokens, through: :api_token_permissions

  validates :name, presence: true, uniqueness: true,
                   format: { with: VALID_FORMAT, message: "must follow format 'resource:action' (e.g. users:read)" }
  validates :description, presence: true

  scope :active, -> { where(deprecated: false) }

  # @return [String] the resource part of the permission name (e.g. "users")
  def resource
    name.split(":").first
  end

  # @return [String] the action part of the permission name (e.g. "read")
  def action
    name.split(":").last
  end
end
