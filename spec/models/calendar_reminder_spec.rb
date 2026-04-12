# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarReminder, type: :model do
  describe 'associations' do
    it { should belong_to(:calendar_event) }
  end

  describe 'validations' do
    subject { build(:calendar_reminder) }

    it { should validate_presence_of(:offset_minutes) }
    it { should validate_presence_of(:fires_at) }
    it { should validate_numericality_of(:offset_minutes).is_greater_than_or_equal_to(0) }

    it 'validates state is one of the allowed values' do
      expect(build(:calendar_reminder, state: 'bogus')).not_to be_valid
    end
  end

  describe 'state transitions' do
    it 'allows pending -> emitted' do
      reminder = create(:calendar_reminder, state: 'pending')
      reminder.mark_emitted!
      expect(reminder.state).to eq 'emitted'
    end

    it 'allows pending -> invalidated' do
      reminder = create(:calendar_reminder, state: 'pending')
      reminder.mark_invalidated!
      expect(reminder.state).to eq 'invalidated'
    end

    it 'allows pending -> expired' do
      reminder = create(:calendar_reminder, state: 'pending')
      reminder.mark_expired!
      expect(reminder.state).to eq 'expired'
    end

    it 'rejects emitted -> pending (terminal state)' do
      reminder = create(:calendar_reminder, state: 'emitted')
      reminder.state = 'pending'
      expect(reminder).not_to be_valid
      expect(reminder.errors[:state].join).to match(/terminal/i)
    end

    it 'rejects invalidated -> emitted' do
      reminder = create(:calendar_reminder, state: 'invalidated')
      expect { reminder.mark_emitted! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'content_snapshot' do
    it 'stores a hash of event attributes at planning time' do
      event = create(:calendar_event, title: 'Dentist', location: 'Paris')
      reminder = create(:calendar_reminder,
                        calendar_event: event,
                        content_snapshot: { 'title' => 'Dentist', 'location' => 'Paris' })
      expect(reminder.reload.content_snapshot).to eq({ 'title' => 'Dentist', 'location' => 'Paris' })
    end
  end
end
