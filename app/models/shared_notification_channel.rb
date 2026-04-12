# frozen_string_literal: true

# An admin-managed shared notification channel. Users may opt into
# one of these after explicitly acknowledging an informed-consent
# warning indicating that messages on shared channels are not
# isolated from other users.
#
# @see NotificationChannel
# @see Mutations::AcknowledgeSharedChannelConsent
# @since 2026-04-11
class SharedNotificationChannel < ApplicationRecord
  ALLOWED_TYPES = %w[ntfy email webhook].freeze

  has_many :notification_channels, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :channel_type, presence: true, inclusion: { in: ALLOWED_TYPES }
  validate :validate_type_specific_config

  # @return [Hash]
  def config
    raw = read_attribute(:config_json)
    raw.present? ? JSON.parse(raw) : {}
  rescue JSON::ParserError
    {}
  end

  # @param value [Hash]
  def config=(value)
    write_attribute(:config_json, JSON.dump(value.to_h))
  end

  private

  def validate_type_specific_config
    case channel_type
    when "ntfy"
      errors.add(:config, "must include a base_url") if config["base_url"].blank?
      errors.add(:config, "must include a topic") if config["topic"].blank?
    when "email"
      errors.add(:config, "must include an address") if config["address"].blank?
    when "webhook"
      url = config["url"].to_s
      errors.add(:config, "must include an HTTPS url") unless url.start_with?("https://")
    end
  end
end
