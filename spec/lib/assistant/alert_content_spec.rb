# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::AlertContent do
  let(:snapshot) do
    {
      "event_id" => 42,
      "external_uid" => "uid-42@example.com",
      "title" => "Dentist",
      "location" => "Paris",
      "description" => "Bring insurance card",
      "starts_at" => "2026-06-12T14:00:00Z",
      "ends_at" => "2026-06-12T15:00:00Z"
    }
  end

  subject(:content) { described_class.from_reminder_snapshot(snapshot, offset_minutes: 15) }

  it "exposes title, location, description" do
    expect(content.title).to eq "Dentist"
    expect(content.location).to eq "Paris"
    expect(content.description).to eq "Bring insurance card"
  end

  it "parses starts_at back to a Time" do
    expect(content.starts_at).to eq Time.utc(2026, 6, 12, 14, 0)
  end

  it "reports the reminder offset" do
    expect(content.offset_minutes).to eq 15
  end

  it "computes a minutes-until-start label" do
    expect(content.time_until_start_label).to eq "in 15 min"
  end

  it "exposes the external uid for linking back" do
    expect(content.external_uid).to eq "uid-42@example.com"
  end

  it "produces a default plain-text body for text-based adapters" do
    body = content.default_text_body
    expect(body).to include("Dentist")
    expect(body).to include("in 15 min")
    expect(body).to include("Paris")
  end
end
