# frozen_string_literal: true

# Creates the alert_emissions table, which is also the storage
# backing for the internal channel A (spec §2.6).
#
# @see AlertEmission
# @since 2026-04-11
class CreateAlertEmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_emissions do |t|
      t.integer :user_id, null: false
      t.integer :calendar_reminder_id, null: false
      t.text :content_snapshot_json, null: false, default: '{}'
      t.datetime :emitted_at, null: false
      t.text :channel_attempts_json, null: false, default: '[]'
      t.timestamps
    end

    add_index :alert_emissions, %i[user_id emitted_at]
    add_index :alert_emissions, :calendar_reminder_id
    add_foreign_key :alert_emissions, :users
    add_foreign_key :alert_emissions, :calendar_reminders
  end
end
