# frozen_string_literal: true

# Lists the current user's reminders within a time window, optionally
# filtered by state. Eager-loads calendar_event to satisfy Bullet in test.
#
# @since 2026-04-11
module Queries
  class AssistantReminders < Queries::BaseQuery
    permission_required "assistant_config:read"

    argument :from, GraphQL::Types::ISO8601DateTime, required: true
    argument :to,   GraphQL::Types::ISO8601DateTime, required: true
    argument :state, String, required: false
    argument :limit, Int, required: false, default_value: 200

    type [ Types::CalendarReminderType ], null: false

    # @param from [Time]
    # @param to [Time]
    # @param limit [Integer]
    # @param state [String, nil]
    # @return [ActiveRecord::Relation]
    def resolve(from:, to:, limit:, state: nil)
      authorize! current_user, to: :read?, with: CalendarReminderPolicy

      scope = CalendarReminder
              .includes(:calendar_event)
              .joins(:calendar_event)
              .where(calendar_events: { user_id: current_user.id })
              .where(fires_at: from..to)
              .order(fires_at: :asc)
              .limit([ limit, 500 ].min)

      scope = scope.where(state: state) if state
      scope
    end
  end
end
