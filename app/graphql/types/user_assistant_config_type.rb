# frozen_string_literal: true

module Types
  # GraphQL type for a user's assistant configuration.
  #
  # @since 2026-04-11
  class UserAssistantConfigType < Types::BaseObject
    field :id, ID, null: false
    field :timezone, String, null: false
    field :reminder_intervals, [ Int ], null: false
    field :calendar_source_type, String, null: false
    field :calendar_source_url, String, null: true
    field :last_polled_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_poll_status, String, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
