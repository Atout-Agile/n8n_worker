# frozen_string_literal: true

# Creates the calendar_reminders table. One row per scheduled
# reminder for a calendar_event.
#
# @see CalendarReminder
# @since 2026-04-11
class CreateCalendarReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_reminders do |t|
      t.integer :calendar_event_id, null: false
      t.integer :offset_minutes, null: false
      t.datetime :fires_at, null: false
      t.string :state, null: false, default: 'pending'
      t.text :content_snapshot_json, null: false, default: '{}'
      t.string :solid_queue_job_key
      t.datetime :fired_at
      t.timestamps
    end

    add_index :calendar_reminders, :calendar_event_id
    add_index :calendar_reminders, %i[state fires_at]
    add_foreign_key :calendar_reminders, :calendar_events
  end
end
