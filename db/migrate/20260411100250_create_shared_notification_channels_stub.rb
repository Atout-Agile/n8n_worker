# frozen_string_literal: true

# Minimal stub table for SharedNotificationChannel.
# This migration exists only to satisfy the ActiveRecord association
# declared in NotificationChannel. Task 4 will replace this with
# the full implementation and a proper migration.
#
# @see SharedNotificationChannel
# @since 2026-04-11
class CreateSharedNotificationChannelsStub < ActiveRecord::Migration[8.0]
  def change
    create_table :shared_notification_channels do |t|
      t.timestamps
    end
  end
end
