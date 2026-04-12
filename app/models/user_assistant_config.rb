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

  validates :user_id, presence: true, uniqueness: true
  validates :timezone, presence: true
  validate :timezone_must_exist
  validate :reminder_intervals_must_be_non_negative_integers

  before_save :encode_reminder_intervals

  # Returns the reminder intervals as an array of integers (minutes).
  # An empty array means "no active reminders" per spec §4.1.
  # Reads the raw JSON column and decodes it on the fly.
  #
  # @return [Array<Integer>]
  def reminder_intervals
    raw = read_attribute(:reminder_intervals_json)
    return [] if raw.blank?

    parsed = raw.is_a?(String) ? (JSON.parse(raw) rescue []) : Array(raw)
    parsed.map(&:to_i)
  end

  # Sets reminder intervals from an Array of integers.
  # Stores the value in a memoised ivar; +before_save+ encodes it as JSON.
  #
  # @param values [Array<Integer>]
  # @return [Array<Integer>]
  def reminder_intervals=(values)
    @reminder_intervals_pending = Array(values)
  end

  # @return [Boolean] true when the user has set a calendar source URL
  def calendar_source_configured?
    calendar_source_url.present?
  end

  private

  # Writes the pending reminder_intervals ivar (if set) to the JSON column
  # as a valid JSON string, bypassing Rails serialization to avoid the
  # ActiveRecord::Type::Serialized default-value check that collapses [] to nil.
  #
  # @api private
  def encode_reminder_intervals
    return unless instance_variable_defined?(:@reminder_intervals_pending)

    write_attribute(:reminder_intervals_json, @reminder_intervals_pending.to_json)
    remove_instance_variable(:@reminder_intervals_pending)
  end

  def timezone_must_exist
    return if timezone.blank?

    errors.add(:timezone, "is not a valid IANA timezone") unless ActiveSupport::TimeZone[timezone]
  end

  def reminder_intervals_must_be_non_negative_integers
    # Use pending ivar if the setter was called (before_save hasn't flushed yet),
    # otherwise fall back to the persisted column value.
    values = if instance_variable_defined?(:@reminder_intervals_pending)
               @reminder_intervals_pending
    else
               reminder_intervals
    end
    return if values.empty?

    return if values.all? { |v| v.is_a?(Integer) && v >= 0 }

    errors.add(:reminder_intervals, "must be a list of non-negative integers (minutes)")
  end
end
