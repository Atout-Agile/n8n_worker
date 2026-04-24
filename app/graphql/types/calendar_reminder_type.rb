# frozen_string_literal: true

module Types
  # GraphQL type for a scheduled reminder.
  #
  # @since 2026-04-11
  class CalendarReminderType < Types::BaseObject
    field :id, ID, null: false
    field :offset_minutes, Int, null: false
    field :fires_at, GraphQL::Types::ISO8601DateTime, null: false
    field :state, String, null: false
    field :fired_at, GraphQL::Types::ISO8601DateTime, null: true
    field :calendar_event, Types::CalendarEventType, null: false
  end
end
