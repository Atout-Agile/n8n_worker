# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarEvent, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:calendar_reminders).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:calendar_event) }

    it { should validate_presence_of(:external_uid) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:starts_at) }
    it { should validate_presence_of(:ends_at) }

    it 'is unique on (user_id, external_uid)' do
      existing = create(:calendar_event)
      duplicate = build(:calendar_event, user: existing.user, external_uid: existing.external_uid)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_uid]).to be_present
    end

    it 'rejects ends_at <= starts_at' do
      t = 1.hour.from_now
      event = build(:calendar_event, starts_at: t, ends_at: t)
      expect(event).not_to be_valid
    end
  end

  describe '#soft_delete!' do
    it 'sets deleted_at to the current time' do
      event = create(:calendar_event)
      travel_to Time.utc(2026, 6, 1, 12, 0) do
        event.soft_delete!
      end
      expect(event.deleted_at).to eq Time.utc(2026, 6, 1, 12, 0)
    end
  end

  describe '#soft_deleted?' do
    it 'is true when deleted_at is set' do
      event = build(:calendar_event, deleted_at: Time.current)
      expect(event.soft_deleted?).to be true
    end
  end

  describe '.scheduled_scope' do
    it 'excludes soft-deleted events' do
      user = create(:user)
      kept = create(:calendar_event, user: user)
      deleted = create(:calendar_event, user: user, deleted_at: Time.current)
      expect(CalendarEvent.scheduled_scope).to include(kept)
      expect(CalendarEvent.scheduled_scope).not_to include(deleted)
    end
  end
end
