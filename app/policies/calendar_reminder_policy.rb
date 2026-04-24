# frozen_string_literal: true

# @since 2026-04-11
class CalendarReminderPolicy < ApplicationPolicy
  def read? = permission?("assistant_config:read")
end
