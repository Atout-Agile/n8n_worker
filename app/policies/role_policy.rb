# frozen_string_literal: true

# Authorization policy for Role records.
#
# @see ApplicationPolicy
# @since 2026-03-29
class RolePolicy < ApplicationPolicy
  # @return [Boolean] true if the current auth context has roles:read
  def read?  = permission?("roles:read")

  # @return [Boolean] true if the current auth context has roles:write
  def write? = permission?("roles:write")
end
