# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::CalendarSyncSchedulerJob, type: :job do
  it 'enqueues a PerUserCalendarSyncJob for every user with a configured calendar source' do
    role = create(:role, :user)
    with_source = create(:user, role: role)
    create(:user_assistant_config, user: with_source, calendar_source_url: 'https://x/y.ics')
    without_source = create(:user, role: role)
    create(:user_assistant_config, user: without_source, calendar_source_url: nil)

    expect do
      described_class.perform_now
    end.to have_enqueued_job(Assistant::PerUserCalendarSyncJob).with(with_source.id).exactly(1).times

    expect(Assistant::PerUserCalendarSyncJob).not_to have_been_enqueued.with(without_source.id)
  end
end
