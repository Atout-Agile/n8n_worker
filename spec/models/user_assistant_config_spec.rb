# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserAssistantConfig, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:user_assistant_config) }

    it { should validate_presence_of(:timezone) }
    it { should validate_uniqueness_of(:user_id) }

    it 'rejects an unknown timezone identifier' do
      config = build(:user_assistant_config, timezone: 'Nowhere/Imaginary')
      expect(config).not_to be_valid
      expect(config.errors[:timezone]).to be_present
    end

    it 'accepts a standard IANA timezone' do
      config = build(:user_assistant_config, user: create(:user), timezone: 'Europe/Paris')
      expect(config).to be_valid
    end

    it 'accepts an empty reminder_intervals list (no active reminders, per spec 4.1)' do
      config = build(:user_assistant_config, user: create(:user), reminder_intervals: [])
      expect(config).to be_valid
    end

    it 'rejects negative reminder offsets' do
      config = build(:user_assistant_config, reminder_intervals: [ 60, -1, 5 ])
      expect(config).not_to be_valid
      expect(config.errors[:reminder_intervals]).to be_present
    end

    it 'rejects non-integer reminder offsets' do
      config = build(:user_assistant_config, reminder_intervals: [ 60, 'fifteen', 5 ])
      expect(config).not_to be_valid
      expect(config.errors[:reminder_intervals]).to be_present
    end
  end

  describe '#calendar_source_configured?' do
    it 'returns false when calendar_source_url is blank' do
      config = build(:user_assistant_config, calendar_source_url: nil)
      expect(config.calendar_source_configured?).to be false
    end

    it 'returns true when calendar_source_url is set' do
      config = build(:user_assistant_config, calendar_source_url: 'https://example.com/feed.ics')
      expect(config.calendar_source_configured?).to be true
    end
  end
end
