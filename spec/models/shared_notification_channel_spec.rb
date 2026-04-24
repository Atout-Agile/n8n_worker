# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SharedNotificationChannel, type: :model do
  describe 'associations' do
    it { should have_many(:notification_channels).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:shared_notification_channel) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:channel_type) }
    it { should validate_uniqueness_of(:name) }

    it 'rejects unknown channel_type values' do
      expect(build(:shared_notification_channel, channel_type: 'sms')).not_to be_valid
    end

    %w[ntfy email webhook].each do |type|
      it "accepts #{type}" do
        channel = build(:shared_notification_channel, channel_type: type, config: minimal_config_for(type))
        expect(channel).to be_valid
      end
    end

    it 'enforces the same type-specific config rules as personal channels' do
      channel = build(:shared_notification_channel, channel_type: 'ntfy', config: {})
      expect(channel).not_to be_valid
    end
  end

  describe '#active?' do
    it 'reflects the active boolean' do
      expect(build(:shared_notification_channel, active: false).active?).to be false
      expect(build(:shared_notification_channel, active: true).active?).to be true
    end
  end

  def minimal_config_for(type)
    case type
    when 'ntfy'    then { 'base_url' => 'https://ntfy.example.com', 'topic' => 'shared-general' }
    when 'email'   then { 'address' => 'shared@example.com' }
    when 'webhook' then { 'url' => 'https://example.com/shared-hook' }
    end
  end
end
