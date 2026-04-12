# frozen_string_literal: true

# Stub model for SharedNotificationChannel.
# Full implementation in Task 4 (feature/assistant_perso_s1).
#
# @since 2026-04-11
# @api private
class SharedNotificationChannel < ApplicationRecord
  has_many :notification_channels, dependent: :nullify
end
