# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assistant::AlertEmitter do
  let(:user) { create(:user) }
  let(:event) { create(:calendar_event, user: user, title: "Dentist", starts_at: 10.minutes.from_now) }
  let(:reminder) do
    create(:calendar_reminder, calendar_event: event, offset_minutes: 5,
           fires_at: event.starts_at - 5.minutes, state: "pending",
           content_snapshot: {
             "event_id" => event.id, "external_uid" => event.external_uid,
             "title" => "Dentist", "location" => nil, "description" => nil,
             "starts_at" => event.starts_at.utc.iso8601, "ends_at" => event.ends_at.utc.iso8601
           })
  end

  let(:success_adapter) do
    double("SuccessAdapter", emit: Assistant::Channels::BaseAdapter::Result.new(status: :success))
  end
  let(:failure_adapter) do
    double("FailureAdapter", emit: Assistant::Channels::BaseAdapter::Result.new(status: :failed, error: "boom"))
  end

  describe "#emit" do
    it "marks the reminder as emitted and records per-channel attempts" do
      create(:notification_channel, :active, user: user, channel_type: "internal")
      create(:notification_channel, :ntfy, :active, user: user)

      allow(Assistant::Channels::Registry).to receive(:adapter_for) do |ch|
        ch.channel_type == "ntfy" ? failure_adapter : success_adapter
      end

      described_class.new.emit(reminder: reminder)

      expect(reminder.reload.state).to eq "emitted"
      emission = user.alert_emissions.order(:created_at).last
      expect(emission.channel_attempts.map { |a| a["status"] }).to include("success", "failed")
    end

    it "does nothing when the reminder is no longer pending" do
      reminder.mark_invalidated!
      allow(Assistant::Channels::Registry).to receive(:adapter_for)
      described_class.new.emit(reminder: reminder)
      expect(Assistant::Channels::Registry).not_to have_received(:adapter_for)
    end

    it "logs an emission with no_channel status when the user has no active channels" do
      described_class.new.emit(reminder: reminder)
      expect(reminder.reload.state).to eq "emitted"
      emission = user.alert_emissions.order(:created_at).last
      expect(emission.channel_attempts.map { |a| a["status"] }).to eq([ "no_channel" ])
    end

    it "treats the reminder as expired if called beyond event_start + grace window" do
      reminder.update!(fires_at: 30.minutes.ago)
      event.update!(starts_at: 25.minutes.ago, ends_at: 24.minutes.ago)
      described_class.new.emit(reminder: reminder)
      expect(reminder.reload.state).to eq "expired"
    end
  end
end
