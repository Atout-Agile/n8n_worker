# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::ReminderPlanner do
  let(:user) { create(:user) }
  let!(:config) { create(:user_assistant_config, user: user, reminder_intervals: [ 60, 15, 5 ]) }

  def build_event(starts_in:)
    create(:calendar_event,
           user: user,
           starts_at: starts_in.from_now,
           ends_at: starts_in.from_now + 1.hour)
  end

  describe '#plan_reminders_for' do
    it 'creates one reminder per future offset' do
      event = build_event(starts_in: 2.hours)
      described_class.new.plan_reminders_for(event, user: user, intervals: [ 60, 15, 5 ])
      expect(event.calendar_reminders.pluck(:offset_minutes)).to contain_exactly(60, 15, 5)
    end

    it 'ignores offsets whose fire time is in the past' do
      event = build_event(starts_in: 10.minutes)
      described_class.new.plan_reminders_for(event, user: user, intervals: [ 60, 15, 5 ])
      expect(event.calendar_reminders.pluck(:offset_minutes)).to contain_exactly(5)
    end

    it 'creates nothing when every offset is in the past' do
      event = build_event(starts_in: 2.minutes)
      described_class.new.plan_reminders_for(event, user: user, intervals: [ 60, 15, 5 ])
      expect(event.calendar_reminders).to be_empty
    end

    it 'freezes the content snapshot at planning time from the event fields' do
      event = build_event(starts_in: 2.hours)
      event.update!(title: 'Dentist', location: 'Paris')
      described_class.new.plan_reminders_for(event, user: user, intervals: [ 15 ])
      reminder = event.calendar_reminders.first
      expect(reminder.content_snapshot).to include(
        'title' => 'Dentist',
        'location' => 'Paris',
        'starts_at' => event.starts_at.utc.iso8601
      )
    end

    it 'creates nothing when the intervals list is empty (spec §4.1)' do
      event = build_event(starts_in: 2.hours)
      described_class.new.plan_reminders_for(event, user: user, intervals: [])
      expect(event.calendar_reminders).to be_empty
    end
  end
end
