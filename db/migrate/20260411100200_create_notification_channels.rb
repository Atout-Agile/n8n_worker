# frozen_string_literal: true

# Creates the notification_channels table. One row per configured
# channel per user, with type-specific configuration as JSON.
# The foreign key to shared_notification_channels is added in
# the next migration (20260411100300).
#
# @see NotificationChannel
# @since 2026-04-11
class CreateNotificationChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_channels do |t|
      t.integer :user_id, null: false
      t.integer :shared_notification_channel_id
      t.string :channel_type, null: false
      t.boolean :active, null: false, default: false
      t.text :config_json, null: false, default: '{}'
      t.datetime :consent_acknowledged_at
      t.timestamps
    end

    add_index :notification_channels, :user_id
    add_index :notification_channels, %i[user_id channel_type]
    add_index :notification_channels, :shared_notification_channel_id
    add_foreign_key :notification_channels, :users
  end
end
