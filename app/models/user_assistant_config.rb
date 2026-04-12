# frozen_string_literal: true

# Per-user assistant configuration. Holds the user's timezone, reminder
# intervals, and calendar source metadata. Created lazily when the user
# first interacts with the assistant subsystem.
#
# @example Access the current user's config
#   config = current_user.assistant_config || current_user.create_assistant_config!
#
# @see User
# @see Assistant::EventReconciler
# @see Assistant::ReminderPlanner
# @since 2026-04-11
class UserAssistantConfig < ApplicationRecord
  belongs_to :user

  serialize :reminder_intervals_json, coder: JSON, type: Array

  validates :user_id, presence: true, uniqueness: true
  validates :timezone, presence: true
  validate :timezone_must_exist
  validate :reminder_intervals_must_be_non_negative_integers

  # Returns the reminder intervals as an array of integers (minutes).
  # An empty array means "no active reminders" per spec §4.1.
  #
  # @return [Array<Integer>]
  def reminder_intervals
    (reminder_intervals_json || []).map(&:to_i)
  end

  # Sets reminder intervals from an Array of integers.
  #
  # @param values [Array<Integer>]
  # @return [Array<Integer>]
  def reminder_intervals=(values)
    self.reminder_intervals_json = Array(values)
  end

  # @return [Boolean] true when the user has set a calendar source URL
  def calendar_source_configured?
    calendar_source_url.present?
  end

  private

  def timezone_must_exist
    return if timezone.blank?

    errors.add(:timezone, "is not a valid IANA timezone") unless ActiveSupport::TimeZone[timezone]
  end

  def reminder_intervals_must_be_non_negative_integers
    values = reminder_intervals_json
    return if values.blank?

    return if values.all? { |v| v.is_a?(Integer) && v >= 0 }

    errors.add(:reminder_intervals, "must be a list of non-negative integers (minutes)")
  end
end
