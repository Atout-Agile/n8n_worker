# frozen_string_literal: true

# Governs access to a user's NotificationChannel records.
#
# @since 2026-04-11
class NotificationChannelPolicy < ApplicationPolicy
  def read? = permission?("assistant_config:read")
  def write? = permission?("assistant_config:write")
end
