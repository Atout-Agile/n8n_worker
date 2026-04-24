# frozen_string_literal: true

# Governs access to UserAssistantConfig.
#
# @see ApplicationPolicy
# @since 2026-04-11
class UserAssistantConfigPolicy < ApplicationPolicy
  def read? = permission?("assistant_config:read")
  def write? = permission?("assistant_config:write")
end
