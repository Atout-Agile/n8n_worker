# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_event do
    user
    sequence(:external_uid) { |n| "uid-#{n}@example.com" }
    title { 'Sample meeting' }
    starts_at { 1.day.from_now }
    ends_at   { 1.day.from_now + 1.hour }
    location { nil }
    description { nil }
    source_last_modified { nil }
    last_seen_at { Time.current }
    disappeared_tick_count { 0 }
    deleted_at { nil }
    raw_payload { nil }
  end
end
