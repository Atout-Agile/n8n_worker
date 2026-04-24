# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertEmission, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:calendar_reminder) }
  end

  describe 'validations' do
    subject { build(:alert_emission) }

    it { should validate_presence_of(:emitted_at) }
  end

  describe '#record_channel_attempt' do
    it 'appends an attempt result to channel_attempts' do
      emission = create(:alert_emission)
      emission.record_channel_attempt('ntfy', status: 'success')
      emission.record_channel_attempt('email', status: 'failed', error: 'SMTP 554')
      expect(emission.reload.channel_attempts).to match([
        hash_including('channel_type' => 'ntfy', 'status' => 'success'),
        hash_including('channel_type' => 'email', 'status' => 'failed', 'error' => 'SMTP 554')
      ])
    end
  end

  describe '.for_user' do
    it 'returns emissions for a given user in reverse chronological order' do
      role = create(:role)
      user = create(:user, role: role)
      other_user = create(:user, role: role)
      older = create(:alert_emission, user: user, emitted_at: 2.hours.ago)
      newer = create(:alert_emission, user: user, emitted_at: 1.hour.ago)
      other_event = create(:calendar_event, user: other_user)
      other_reminder = create(:calendar_reminder, calendar_event: other_event)
      create(:alert_emission, user: other_user,
             calendar_reminder: other_reminder) # another user
      expect(AlertEmission.for_user(user)).to eq([ newer, older ])
    end
  end
end
