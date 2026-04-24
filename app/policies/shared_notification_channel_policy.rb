# frozen_string_literal: true

# Reading shared channels is available to any user with
# `assistant_shared_channels:read`. Managing them requires
# `assistant_shared_channels:write` (admin-only).
#
# @since 2026-04-11
class SharedNotificationChannelPolicy < ApplicationPolicy
  def read? = permission?("assistant_shared_channels:read")
  def write? = permission?("assistant_shared_channels:write")
end
