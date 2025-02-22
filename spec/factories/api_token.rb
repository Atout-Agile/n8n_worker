# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    sequence(:name) { |n| "Token #{n}" }
    token_digest { SecureRandom.hex(32) }
    last_used_at { nil }
    expires_at { 30.days.from_now }
    association :user
  end
end 