# frozen_string_literal: true

FactoryBot.define do
  factory :alert_emission do
    user
    calendar_reminder do
      event = association(:calendar_event, user: user)
      association(:calendar_reminder, calendar_event: event)
    end
    content_snapshot { { 'title' => 'Sample meeting' } }
    emitted_at { Time.current }
    channel_attempts { [] }
  end
end
