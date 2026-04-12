# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assistant::Channels::NtfyAdapter do
  let(:user) { create(:user) }
  let(:channel) do
    create(:notification_channel, :ntfy, :active, user: user,
           config: { "base_url" => "https://ntfy.example.com", "topic" => "user-42" })
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
    it "POSTs to the ntfy topic URL with Title header and body" do
      stub = stub_request(:post, "https://ntfy.example.com/user-42")
             .with(
               headers: { "Title" => "Dentist", "Content-Type" => "text/plain; charset=utf-8" },
               body: /Dentist.*in 15 min/m
             )
             .to_return(status: 200)
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(stub).to have_been_requested
      expect(result).to be_success
    end

    it "returns failure on HTTP 500" do
      stub_request(:post, "https://ntfy.example.com/user-42").to_return(status: 500)
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).not_to be_success
      expect(result.error).to include("HTTP 500")
    end

    it "returns failure on connection error" do
      stub_request(:post, "https://ntfy.example.com/user-42").to_raise(SocketError.new("unreachable"))
      result = described_class.new(channel: channel).emit(content: content, reminder: reminder)
      expect(result).not_to be_success
      expect(result.error).to include("unreachable")
    end
  end
end
