# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assistant::Channels::WebhookAdapter do
  let(:user) { create(:user) }
  let(:channel) do
    create(:notification_channel, :webhook, :active, user: user,
           config: { "url" => "https://hook.example.com/alerts" })
  end
  let(:event) { create(:calendar_event, user: user) }
  let(:reminder) { create(:calendar_reminder, calendar_event: event) }
  let(:content) do
    Assistant::AlertContent.new(
      event_id: 1, external_uid: "u1", title: "Dentist",
      location: "Paris", description: "Bring card",
      starts_at: Time.utc(2026, 6, 12, 14), ends_at: Time.utc(2026, 6, 12, 15),
      offset_minutes: 15
    )
  end

  describe "#emit" do
    it "POSTs a JSON payload to the webhook URL" do
      stub_request(:post, "https://hook.example.com/alerts")
        .with(
          headers: { "Content-Type" => "application/json" },
          body: hash_including("title" => "Dentist", "offset_minutes" => 15)
        )
        .to_return(status: 200)
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).to be_success
    end

    it "returns failure on non-2xx" do
      stub_request(:post, "https://hook.example.com/alerts").to_return(status: 500)
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).not_to be_success
    end
  end
end
