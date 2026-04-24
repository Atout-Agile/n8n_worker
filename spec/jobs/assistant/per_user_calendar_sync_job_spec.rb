# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::PerUserCalendarSyncJob, type: :job do
  let(:user) { create(:user) }

  context 'when the user has no calendar source configured' do
    it 'is a no-op' do
      create(:user_assistant_config, user: user, calendar_source_url: nil)
      expect(Assistant::IcsFetcher).not_to receive(:new)
      described_class.perform_now(user.id)
    end
  end

  context 'when the fetch fails' do
    it 'updates last_poll_status to failure and does not raise' do
      create(:user_assistant_config, user: user, calendar_source_url: 'https://x/y.ics')
      fetcher = instance_double(Assistant::IcsFetcher)
      allow(Assistant::IcsFetcher).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:fetch).and_return(
        Assistant::IcsFetcher::Result.new(body: nil, error: 'timeout')
      )
      described_class.perform_now(user.id)
      expect(user.assistant_config.reload.last_poll_status).to include('failure')
    end
  end

  context 'when the fetch succeeds' do
    it 'parses, reconciles, and schedules FireReminderJob for each new reminder' do
      create(:user_assistant_config, user: user, calendar_source_url: 'https://x/y.ics',
                                     reminder_intervals: [ 60, 15, 5 ])
      fetcher = instance_double(Assistant::IcsFetcher)
      allow(Assistant::IcsFetcher).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:fetch).and_return(
        Assistant::IcsFetcher::Result.new(body: "BEGIN:VCALENDAR\nEND:VCALENDAR", error: nil)
      )
      parser = instance_double(Assistant::IcsParser)
      allow(Assistant::IcsParser).to receive(:new).and_return(parser)
      allow(parser).to receive(:parse).and_return([
        Assistant::ParsedEvent.new(
          external_uid: 'new@x', title: 'Meeting',
          starts_at: 2.hours.from_now, ends_at: 2.hours.from_now + 30.minutes,
          location: nil, description: nil, source_last_modified: nil,
          all_day: false, raw_payload: 'raw'
        )
      ])

      expect do
        described_class.perform_now(user.id)
      end.to have_enqueued_job(Assistant::FireReminderJob).exactly(3).times
      expect(user.calendar_events.count).to eq 1
      expect(user.assistant_config.reload.last_poll_status).to include('success')
    end
  end
end
