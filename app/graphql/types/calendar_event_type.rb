# frozen_string_literal: true

module Types
  # GraphQL type for an observed calendar event.
  #
  # @since 2026-04-11
  class CalendarEventType < Types::BaseObject
    field :id, ID, null: false
    field :external_uid, String, null: false
    field :title, String, null: false
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: false
    field :ends_at, GraphQL::Types::ISO8601DateTime, null: false
    field :location, String, null: true
    field :description, String, null: true
    field :last_seen_at, GraphQL::Types::ISO8601DateTime, null: false
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: true
  end
end
