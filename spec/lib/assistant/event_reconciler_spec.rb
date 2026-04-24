# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::EventReconciler do
  let(:user) { create(:user) }
  let!(:config) { create(:user_assistant_config, user: user, reminder_intervals: [ 60, 15, 5 ]) }

  def parsed_event(uid:, title: 'Meeting', starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, last_modified: nil)
    Assistant::ParsedEvent.new(
      external_uid: uid,
      title: title,
      starts_at: starts_at.utc,
      ends_at: ends_at.utc,
      location: nil,
      description: nil,
      source_last_modified: last_modified,
      all_day: false,
      raw_payload: 'VEVENT-raw'
    )
  end

  describe '#reconcile' do
    context 'with a brand new event' do
      it 'creates the CalendarEvent and schedules reminders for future offsets only' do
        parsed = [ parsed_event(uid: 'a@x', starts_at: 2.hours.from_now) ]
        summary = described_class.new(user: user).reconcile(parsed)
        event = user.calendar_events.find_by(external_uid: 'a@x')
        expect(event).to be_present
        expect(event.calendar_reminders.pluck(:offset_minutes)).to contain_exactly(60, 15, 5)
        expect(summary.created).to eq 1
      end

      it 'skips reminder offsets whose target time is already in the past' do
        parsed = [ parsed_event(uid: 'b@x', starts_at: 10.minutes.from_now) ]
        described_class.new(user: user).reconcile(parsed)
        event = user.calendar_events.find_by(external_uid: 'b@x')
        expect(event.calendar_reminders.pluck(:offset_minutes)).to contain_exactly(5)
      end
    end

    context 'with an unchanged event' do
      it 'updates last_seen_at without touching reminders' do
        existing = create(:calendar_event,
                          user: user,
                          external_uid: 'keep@x',
                          starts_at: 2.days.from_now,
                          ends_at: 2.days.from_now + 1.hour,
                          source_last_modified: 1.day.ago,
                          last_seen_at: 1.hour.ago)
        create(:calendar_reminder, calendar_event: existing, offset_minutes: 60,
                                   fires_at: existing.starts_at - 60.minutes)
        parsed = [ parsed_event(uid: 'keep@x',
                               title: existing.title,
                               starts_at: existing.starts_at,
                               ends_at: existing.ends_at,
                               last_modified: existing.source_last_modified) ]
        described_class.new(user: user).reconcile(parsed)
        existing.reload
        expect(existing.last_seen_at).to be > 1.minute.ago
        expect(existing.calendar_reminders.pending.size).to eq 1
      end
    end

    context 'with a temporally modified event' do
      it 'invalidates existing pending reminders and creates new ones' do
        existing = create(:calendar_event,
                          user: user,
                          external_uid: 'move@x',
                          starts_at: 3.days.from_now,
                          ends_at: 3.days.from_now + 1.hour)
        old_reminder = create(:calendar_reminder, calendar_event: existing,
                              offset_minutes: 60, fires_at: existing.starts_at - 60.minutes)
        parsed = [ parsed_event(uid: 'move@x',
                               title: existing.title,
                               starts_at: existing.starts_at + 1.day,
                               ends_at: existing.ends_at + 1.day) ]
        described_class.new(user: user).reconcile(parsed)
        expect(old_reminder.reload.state).to eq 'invalidated'
        expect(existing.reload.calendar_reminders.pending.size).to eq 3
      end
    end

    context 'with a disappeared event' do
      it 'increments disappeared_tick_count and soft-deletes once the grace threshold is reached' do
        existing = create(:calendar_event, user: user, external_uid: 'gone@x', disappeared_tick_count: 0)
        create(:calendar_reminder, calendar_event: existing, state: 'pending',
               fires_at: existing.starts_at - 15.minutes)

        tick_count = Assistant::Settings.current.disappearance_grace_ticks

        tick_count.times do
          described_class.new(user: user).reconcile([])
        end

        existing.reload
        expect(existing.disappeared_tick_count).to eq tick_count
        expect(existing.deleted_at).to be_present
        expect(existing.calendar_reminders.where(state: 'invalidated')).to be_present
      end

      it 'resurrects a grace-pending event if it comes back before soft delete' do
        existing = create(:calendar_event, user: user, external_uid: 'flicker@x', disappeared_tick_count: 0)
        described_class.new(user: user).reconcile([])
        expect(existing.reload.disappeared_tick_count).to eq 1

        parsed = [ parsed_event(uid: 'flicker@x', title: existing.title,
                               starts_at: existing.starts_at, ends_at: existing.ends_at) ]
        described_class.new(user: user).reconcile(parsed)
        expect(existing.reload.disappeared_tick_count).to eq 0
        expect(existing.reload.deleted_at).to be_nil
      end
    end
  end
end
