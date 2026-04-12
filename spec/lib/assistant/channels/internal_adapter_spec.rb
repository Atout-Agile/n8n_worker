# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::Channels::InternalAdapter do
  let(:user) { create(:user) }
  let(:event) { create(:calendar_event, user: user, title: 'Dentist') }
  let(:reminder) { create(:calendar_reminder, calendar_event: event, offset_minutes: 15) }
  let(:content) do
    Assistant::AlertContent.from_reminder_snapshot(
      reminder.content_snapshot.merge('title' => 'Dentist'),
      offset_minutes: 15
    )
  end
  let(:channel) { create(:notification_channel, user: user, channel_type: 'internal', active: true) }

  describe '#emit' do
    it 'creates an AlertEmission row for the user with the content snapshot' do
      expect do
        described_class.new(channel: channel).emit(content: content, reminder: reminder)
      end.to change(AlertEmission, :count).by(1)
      emission = AlertEmission.last
      expect(emission.user).to eq user
      expect(emission.calendar_reminder).to eq reminder
      expect(emission.content_snapshot).to include('title' => 'Dentist')
    end

    it 'returns a success result' do
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).to be_success
    end
  end
end
