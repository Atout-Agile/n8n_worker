# frozen_string_literal: true

FactoryBot.define do
  factory :notification_channel do
    user
    channel_type { 'internal' }
    active { false }
    config { {} }
    consent_acknowledged_at { nil }
    shared_notification_channel { nil }

    trait :ntfy do
      channel_type { 'ntfy' }
      config { { 'base_url' => 'https://ntfy.example.com', 'topic' => "user-#{SecureRandom.hex(4)}" } }
    end

    trait :email do
      channel_type { 'email' }
      config { { 'address' => 'user@example.com' } }
    end

    trait :webhook do
      channel_type { 'webhook' }
      config { { 'url' => 'https://example.com/hook' } }
    end

    trait :shared do
      channel_type { 'shared' }
      shared_notification_channel
      consent_acknowledged_at { Time.current }
      config { {} }
    end

    trait :active do
      active { true }
    end
  end
end
