# frozen_string_literal: true

module Types
  # GraphQL type for a user's notification channel.
  #
  # @since 2026-04-11
  class NotificationChannelType < Types::BaseObject
    field :id, ID, null: false
    field :channel_type, String, null: false
    field :active, Boolean, null: false
    field :config, GraphQL::Types::JSON, null: false
    field :consent_acknowledged_at, GraphQL::Types::ISO8601DateTime, null: true
    field :shared_notification_channel, Types::SharedNotificationChannelType, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
