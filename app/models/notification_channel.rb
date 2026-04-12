# frozen_string_literal: true

# A channel configured by a user to receive assistant alerts.
# At least one active channel is required for a user to receive
# any reminder (spec §1.3 point 10). Channels come in five types:
# internal, ntfy, email, webhook, shared.
#
# @see User
# @see SharedNotificationChannel
# @see Assistant::Channels::Registry
# @since 2026-04-11
class NotificationChannel < ApplicationRecord
  CHANNEL_TYPES = %w[internal ntfy email webhook shared].freeze

  belongs_to :user
  belongs_to :shared_notification_channel, optional: true

  attribute :active, :boolean, default: false

  before_validation :set_defaults

  validates :channel_type, inclusion: { in: CHANNEL_TYPES }
  validate :validate_type_specific_config
  validate :validate_shared_channel_link
  validate :validate_shared_consent_present

  # Returns the type-specific configuration as a Hash.
  #
  # @return [Hash]
  def config
    raw = read_attribute(:config_json)
    return {} if raw.blank?

    raw.is_a?(Hash) ? raw : JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end

  # Stores a Hash as a JSON string in config_json.
  #
  # @param value [Hash]
  def config=(value)
    write_attribute(:config_json, JSON.dump(value.to_h))
  end

  private

  def set_defaults
    self.active = false if active.nil?
    write_attribute(:config_json, "{}") if read_attribute(:config_json).blank?
  end

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

  def validate_shared_channel_link
    return unless channel_type == "shared"
    return if shared_notification_channel.present?

    errors.add(:shared_notification_channel, "must be set for shared channels")
  end

  def validate_shared_consent_present
    return unless channel_type == "shared"
    return if consent_acknowledged_at.present?

    errors.add(:consent_acknowledged_at, "is required before activating a shared channel")
  end
end
