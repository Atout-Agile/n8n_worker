# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assistant::Channels::Registry do
  let(:user) { create(:user) }

  {
    "internal" => Assistant::Channels::InternalAdapter,
    "ntfy" => Assistant::Channels::NtfyAdapter,
    "email" => Assistant::Channels::EmailAdapter,
    "webhook" => Assistant::Channels::WebhookAdapter
  }.each do |type, adapter_class|
    it "returns #{adapter_class.name} for channel_type=#{type}" do
      channel = build(:notification_channel, user: user, channel_type: type)
      expect(described_class.adapter_for(channel)).to be_a(adapter_class)
    end
  end

  it "returns the inner type's adapter for a shared channel" do
    shared = create(:shared_notification_channel, channel_type: "ntfy",
                    config: { "base_url" => "https://ntfy.example.com", "topic" => "shared-x" })
    channel = create(:notification_channel, :shared, user: user,
                     shared_notification_channel: shared,
                     consent_acknowledged_at: Time.current)
    expect(described_class.adapter_for(channel)).to be_a(Assistant::Channels::NtfyAdapter)
  end

  it "raises for an unknown channel_type" do
    channel = build(:notification_channel, user: user, channel_type: "internal")
    allow(channel).to receive(:channel_type).and_return("bogus")
    expect { described_class.adapter_for(channel) }.to raise_error(ArgumentError)
  end
end
