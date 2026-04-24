# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assistant::Channels::EmailAdapter do
  include ActionMailer::TestHelper

  let(:user) { create(:user) }
  let(:channel) do
    create(:notification_channel, :email, :active, user: user,
           config: { "address" => "user@example.com" })
  end
  let(:event) { create(:calendar_event, user: user) }
  let(:reminder) { create(:calendar_reminder, calendar_event: event) }
  let(:content) do
    Assistant::AlertContent.new(
      event_id: 1, external_uid: "u1", title: "Dentist",
      location: "Paris", description: "Bring insurance card",
      starts_at: Time.utc(2026, 6, 12, 14), ends_at: Time.utc(2026, 6, 12, 15),
      offset_minutes: 15
    )
  end

  describe "#emit" do
    it "enqueues a reminder_alert email to the configured address" do
      expect do
        described_class.new(channel: channel).emit(content: content, reminder: reminder)
      end.to have_enqueued_mail(AssistantMailer, :reminder_alert)
    end

    it "returns success" do
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).to be_success
    end

    it "renders the email with expected subject and body" do
      AssistantMailer.reminder_alert(
        address: "user@example.com",
        title: content.title,
        time_until_start_label: content.time_until_start_label,
        starts_at: content.starts_at&.utc&.iso8601,
        ends_at: content.ends_at&.utc&.iso8601,
        location: content.location,
        description: content.description
      ).deliver_now
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ "user@example.com" ])
      expect(email.subject).to include("Dentist")
      expect(email.body.encoded).to include("in 15 min")
    end
  end
end
