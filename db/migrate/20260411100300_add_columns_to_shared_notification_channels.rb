# frozen_string_literal: true

# Completes the shared_notification_channels table. The table was created as
# a stub by the previous migration (20260411100250). This migration adds all
# remaining columns, the unique name index, and the FK from notification_channels.
#
# @see SharedNotificationChannel
# @since 2026-04-11
class AddColumnsToSharedNotificationChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :shared_notification_channels, :name, :string, null: false, default: ''
    add_column :shared_notification_channels, :channel_type, :string, null: false, default: ''
    add_column :shared_notification_channels, :config_json, :text, null: false, default: '{}'
    add_column :shared_notification_channels, :active, :boolean, null: false, default: true

    add_index :shared_notification_channels, :name, unique: true
    add_foreign_key :notification_channels, :shared_notification_channels
  end
end
