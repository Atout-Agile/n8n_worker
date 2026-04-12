# frozen_string_literal: true

# A scheduled reminder for a calendar event. Holds the frozen content
# snapshot captured when the reminder was planned, so that the emitted
# alert reflects the event's state at planning time rather than at fire
# time (spec §2.5). Terminal states are never reverted.
#
# @see CalendarEvent
# @see Assistant::ReminderPlanner
# @see Assistant::AlertEmitter
# @since 2026-04-11
class CalendarReminder < ApplicationRecord
  STATES = %w[pending emitted invalidated expired].freeze
  TERMINAL_STATES = %w[emitted invalidated expired].freeze

  belongs_to :calendar_event

  validates :offset_minutes, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :fires_at, presence: true
  validates :state, inclusion: { in: STATES }
  validate :terminal_state_is_immutable

  scope :pending, -> { where(state: "pending") }
  scope :fireable_now, ->(at = Time.current) { pending.where(fires_at: ..at) }

  # @return [Hash]
  def content_snapshot
    raw = read_attribute(:content_snapshot_json)
    raw.present? ? JSON.parse(raw) : {}
  rescue JSON::ParserError
    {}
  end

  # @param value [Hash]
  def content_snapshot=(value)
    write_attribute(:content_snapshot_json, JSON.dump(value.to_h))
  end

  # @return [void]
  def mark_emitted!
    update!(state: "emitted", fired_at: Time.current)
  end

  # @return [void]
  def mark_invalidated!
    update!(state: "invalidated")
  end

  # @return [void]
  def mark_expired!
    update!(state: "expired")
  end

  private

  def terminal_state_is_immutable
    return unless state_changed? && TERMINAL_STATES.include?(state_was)

    errors.add(:state, "cannot transition out of terminal state #{state_was}")
  end
end
