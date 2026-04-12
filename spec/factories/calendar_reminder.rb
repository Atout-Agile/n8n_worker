# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_reminder do
    calendar_event
    offset_minutes { 15 }
    fires_at { 1.day.from_now - 15.minutes }
    state { 'pending' }
    content_snapshot { { 'title' => 'Sample meeting' } }
    solid_queue_job_key { nil }
    fired_at { nil }
  end
end
