# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::FireReminderJob, type: :job do
  let(:reminder) { create(:calendar_reminder, state: 'pending') }

  it 'calls AlertEmitter#emit with the given reminder' do
    emitter = instance_double(Assistant::AlertEmitter)
    allow(Assistant::AlertEmitter).to receive(:new).and_return(emitter)
    expect(emitter).to receive(:emit).with(reminder: reminder)
    described_class.perform_now(reminder.id)
  end

  it 'is a no-op when the reminder has been deleted' do
    reminder_id = reminder.id
    reminder.calendar_event.destroy
    expect { described_class.perform_now(reminder_id) }.not_to raise_error
  end
end
