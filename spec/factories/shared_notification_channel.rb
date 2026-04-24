# frozen_string_literal: true

FactoryBot.define do
  factory :shared_notification_channel do
    sequence(:name) { |n| "shared-channel-#{n}" }
    channel_type { 'ntfy' }
    active { true }
    config { { 'base_url' => 'https://ntfy.example.com', 'topic' => 'shared-general' } }
  end
end
