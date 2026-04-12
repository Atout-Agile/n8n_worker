# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::IcsParser do
  let(:simple_ics) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Example//EN
      BEGIN:VEVENT
      UID:abc-123@example.com
      SUMMARY:Dentist
      LOCATION:12 rue X
      DESCRIPTION:Bring insurance card
      DTSTART:20260612T140000Z
      DTEND:20260612T150000Z
      LAST-MODIFIED:20260601T090000Z
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  describe '#parse' do
    it 'returns an array of ParsedEvent with all expected fields' do
      events = described_class.new.parse(simple_ics)
      expect(events.size).to eq 1
      ev = events.first
      expect(ev.external_uid).to eq 'abc-123@example.com'
      expect(ev.title).to eq 'Dentist'
      expect(ev.location).to eq '12 rue X'
      expect(ev.description).to eq 'Bring insurance card'
      expect(ev.starts_at).to eq Time.utc(2026, 6, 12, 14, 0)
      expect(ev.ends_at).to eq Time.utc(2026, 6, 12, 15, 0)
      expect(ev.source_last_modified).to eq Time.utc(2026, 6, 1, 9, 0)
      expect(ev.all_day?).to be false
      expect(ev.raw_payload).to include('VEVENT')
    end

    it 'flags all-day events and sets starts_at to 00:00 of the date' do
      ics = <<~ICS
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        UID:ad-1@example.com
        SUMMARY:Holiday
        DTSTART;VALUE=DATE:20260614
        DTEND;VALUE=DATE:20260615
        END:VEVENT
        END:VCALENDAR
      ICS
      ev = described_class.new.parse(ics).first
      expect(ev.all_day?).to be true
      expect(ev.starts_at).to eq Time.utc(2026, 6, 14, 0, 0)
      expect(ev.ends_at).to eq Time.utc(2026, 6, 15, 0, 0)
    end

    it 'expands recurring events into their occurrences up to a horizon' do
      ics = <<~ICS
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        UID:rec-1@example.com
        SUMMARY:Daily standup
        DTSTART:20260601T080000Z
        DTEND:20260601T081500Z
        RRULE:FREQ=DAILY;COUNT=3
        END:VEVENT
        END:VCALENDAR
      ICS
      events = described_class.new.parse(ics, horizon: Time.utc(2026, 6, 4))
      expect(events.size).to eq 3
      expect(events.map(&:external_uid).uniq.size).to eq 3
      expect(events.map(&:starts_at)).to eq [
        Time.utc(2026, 6, 1, 8, 0),
        Time.utc(2026, 6, 2, 8, 0),
        Time.utc(2026, 6, 3, 8, 0)
      ]
    end

    it 'returns an empty array for malformed events without raising' do
      ics = <<~ICS
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        END:VEVENT
        END:VCALENDAR
      ICS
      expect { described_class.new.parse(ics) }.not_to raise_error
      expect(described_class.new.parse(ics)).to eq []
    end
  end
end
