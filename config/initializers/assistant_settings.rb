# frozen_string_literal: true

# Loads system-wide assistant settings from environment variables and
# freezes them for the lifetime of the process. Re-deployment is
# required to change any value.
#
# @see Assistant::Settings
Rails.application.config.after_initialize do
  Assistant::Settings.configure(
    sync_interval_seconds: ENV["ASSISTANT_SYNC_INTERVAL_SECONDS"]&.to_i,
    disappearance_grace_ticks: ENV["ASSISTANT_DISAPPEARANCE_GRACE_TICKS"]&.to_i,
    planning_horizon_days: ENV["ASSISTANT_PLANNING_HORIZON_DAYS"]&.to_i,
    retry_grace_seconds: ENV["ASSISTANT_RETRY_GRACE_SECONDS"]&.to_i,
    default_reminder_intervals: ENV["ASSISTANT_DEFAULT_REMINDER_INTERVALS"]&.split(",")&.map(&:to_i)
  )
end
