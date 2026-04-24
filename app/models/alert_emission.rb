# frozen_string_literal: true

# A single recorded alert emission for a user. Each row also acts
# as one entry in the internal channel A feed (spec §2.6). Stores
# the frozen content snapshot and a list of per-channel attempt
# results.
#
# @see User
# @see CalendarReminder
# @see Assistant::Channels::InternalAdapter
# @since 2026-04-11
class AlertEmission < ApplicationRecord
  belongs_to :user
  belongs_to :calendar_reminder

  validates :emitted_at, presence: true

  scope :for_user, ->(user) { where(user_id: user.id).order(emitted_at: :desc) }

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

  # @return [Array<Hash>]
  def channel_attempts
    raw = read_attribute(:channel_attempts_json)
    raw.present? ? JSON.parse(raw) : []
  rescue JSON::ParserError
    []
  end

  # @param value [Array<Hash>]
  def channel_attempts=(value)
    write_attribute(:channel_attempts_json, JSON.dump(Array(value)))
  end

  # Appends a per-channel result and persists the row.
  #
  # @param channel_type [String] e.g. "ntfy", "email", "webhook", "internal", "shared"
  # @param status [String] "success", "failed", "abandoned", or "no_channel"
  # @param error [String, nil] optional error description
  # @return [void]
  def record_channel_attempt(channel_type, status:, error: nil)
    attempts = channel_attempts + [ {
      "channel_type" => channel_type,
      "status" => status,
      "error" => error,
      "at" => Time.current.iso8601
    }.compact ]
    update!(channel_attempts_json: JSON.dump(attempts))
  end
end
