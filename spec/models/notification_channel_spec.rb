# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationChannel, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:shared_notification_channel).optional }
  end

  describe 'channel_type' do
    %w[internal ntfy email webhook].each do |type|
      it "accepts #{type}" do
        channel = build(:notification_channel, channel_type: type, config: minimal_config_for(type))
        expect(channel).to be_valid
      end
    end

    it 'accepts shared', pending: 'awaiting Task 4' do
      channel = build(:notification_channel, channel_type: 'shared', config: {})
      channel.shared_notification_channel = build(:shared_notification_channel)
      channel.consent_acknowledged_at = Time.current
      expect(channel).to be_valid
    end

    it 'rejects unknown values' do
      channel = build(:notification_channel, channel_type: 'sms')
      expect(channel).not_to be_valid
    end
  end

  describe 'per-type config validation' do
    it 'requires base_url and topic for ntfy' do
      channel = build(:notification_channel, channel_type: 'ntfy', config: {})
      expect(channel).not_to be_valid
      expect(channel.errors[:config]).to be_present
    end

    it 'requires an address for email' do
      channel = build(:notification_channel, channel_type: 'email', config: {})
      expect(channel).not_to be_valid
    end

    it 'requires an HTTPS url for webhook' do
      channel = build(:notification_channel, channel_type: 'webhook', config: { 'url' => 'ftp://example.com' })
      expect(channel).not_to be_valid
    end

    it 'requires consent_acknowledged_at for shared', pending: 'awaiting Task 4' do
      shared = create(:shared_notification_channel)
      channel = build(:notification_channel,
                      channel_type: 'shared',
                      shared_notification_channel: shared,
                      consent_acknowledged_at: nil)
      expect(channel).not_to be_valid
      expect(channel.errors[:consent_acknowledged_at]).to be_present
    end

    it 'does not require consent for non-shared channels' do
      channel = build(:notification_channel, channel_type: 'ntfy', consent_acknowledged_at: nil,
                                              config: { 'base_url' => 'https://ntfy.example.com', 'topic' => 'u1' })
      expect(channel).to be_valid
    end

    it 'requires nothing extra for internal channel' do
      channel = build(:notification_channel, channel_type: 'internal', config: {})
      expect(channel).to be_valid
    end
  end

  describe 'default state' do
    it 'is inactive by default (no channel is active until user explicitly enables it)' do
      channel = build(:notification_channel, channel_type: 'internal', active: nil, config: {})
      channel.save
      expect(channel.active).to be false
    end
  end

  def minimal_config_for(type)
    case type
    when 'ntfy'    then { 'base_url' => 'https://ntfy.example.com', 'topic' => 'user-123' }
    when 'email'   then { 'address' => 'user@example.com' }
    when 'webhook' then { 'url' => 'https://example.com/hook' }
    else                {}
    end
  end
end
