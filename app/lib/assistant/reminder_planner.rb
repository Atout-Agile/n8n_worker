# frozen_string_literal: true

module Assistant
  # Temporary stub. Replaced in Task 12.
  class ReminderPlanner
    def plan_reminders_for(event, user:, intervals:)
      intervals.each do |offset|
        fires_at = event.starts_at - offset.minutes
        next if fires_at <= Time.current

        event.calendar_reminders.create!(
          offset_minutes: offset,
          fires_at: fires_at,
          state: "pending",
          content_snapshot: { "title" => event.title }
        )
      end
    end
  end
end
