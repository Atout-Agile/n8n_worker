# frozen_string_literal: true

module Types
  # GraphQL type for a recorded alert emission (internal channel A).
  #
  # @since 2026-04-11
  class AlertEmissionType < Types::BaseObject
    field :id, ID, null: false
    field :emitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :content_snapshot, GraphQL::Types::JSON, null: false
    field :channel_attempts, [ GraphQL::Types::JSON ], null: false
  end
end
