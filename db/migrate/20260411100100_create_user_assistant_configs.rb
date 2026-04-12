# frozen_string_literal: true

# Creates the user_assistant_configs table, one row per user.
#
# @see UserAssistantConfig
# @since 2026-04-11
class CreateUserAssistantConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :user_assistant_configs do |t|
      t.integer :user_id, null: false
      t.string :timezone, null: false, default: 'UTC'
      t.text :reminder_intervals_json, null: false, default: '[60,15,5]'
      t.string :calendar_source_type, null: false, default: 'ics'
      t.string :calendar_source_url
      t.datetime :last_polled_at
      t.string :last_poll_status
      t.timestamps
    end

    add_index :user_assistant_configs, :user_id, unique: true
    add_foreign_key :user_assistant_configs, :users
  end
end
