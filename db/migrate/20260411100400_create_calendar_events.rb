# frozen_string_literal: true

# Creates the calendar_events table. One row per observed event per user.
#
# @see CalendarEvent
# @since 2026-04-11
class CreateCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_events do |t|
      t.integer :user_id, null: false
      t.string :external_uid, null: false
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :location
      t.text :description
      t.datetime :source_last_modified
      t.datetime :last_seen_at, null: false
      t.integer :disappeared_tick_count, null: false, default: 0
      t.datetime :deleted_at
      t.text :raw_payload
      t.timestamps
    end

    add_index :calendar_events, %i[user_id external_uid], unique: true
    add_index :calendar_events, %i[user_id starts_at]
    add_index :calendar_events, :deleted_at
    add_foreign_key :calendar_events, :users
  end
end
