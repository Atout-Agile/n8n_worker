# frozen_string_literal: true

# Governs access to a user's AlertEmission records (internal channel A).
#
# @since 2026-04-11
class AlertEmissionPolicy < ApplicationPolicy
  def read? = permission?("assistant_alerts:read")
  def write? = permission?("assistant_alerts:write")
end
