# frozen_string_literal: true

# A calendar event observed for one user from the user's ICS source.
# Serves as the authoritative local representation of the event between
# polls; its characteristics feed into reminder scheduling.
#
# Soft delete is used so that a briefly-missing event can be revived
# without losing associated reminder history (spec §3.10).
#
# @see User
# @see CalendarReminder
# @see Assistant::EventReconciler
# @since 2026-04-11
class CalendarEvent < ApplicationRecord
  belongs_to :user
  has_many :calendar_reminders, dependent: :destroy

  validates :external_uid, presence: true
  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :external_uid, uniqueness: { scope: :user_id }
  validate :ends_at_after_starts_at

  scope :scheduled_scope, -> { where(deleted_at: nil) }

  # Marks the event as soft-deleted by setting deleted_at to the current time.
  #
  # @return [void]
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # @return [Boolean]
  def soft_deleted?
    deleted_at.present?
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after starts_at") if ends_at <= starts_at
  end
end
