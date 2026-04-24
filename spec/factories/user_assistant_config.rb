# frozen_string_literal: true

FactoryBot.define do
  factory :user_assistant_config do
    user
    timezone { 'Europe/Paris' }
    reminder_intervals { [ 60, 15, 5 ] }
    calendar_source_type { 'ics' }
    calendar_source_url { nil }
    last_polled_at { nil }
    last_poll_status { nil }
  end
end
