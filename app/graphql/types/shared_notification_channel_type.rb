# frozen_string_literal: true

module Types
  # GraphQL type for an admin-managed shared notification channel.
  #
  # @since 2026-04-11
  class SharedNotificationChannelType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :channel_type, String, null: false
    field :active, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
