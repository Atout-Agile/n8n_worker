# frozen_string_literal: true

# Sends assistant reminder emails.
#
# @see Assistant::Channels::EmailAdapter
# @see Assistant::AlertContent
# @since 2026-04-11
class AssistantMailer < ApplicationMailer
  default from: "assistant@localhost"

  # Sends one reminder alert email.
  #
  # @param address [String] target email address
  # @param content [Assistant::AlertContent] alert content (accepts struct or hash-like)
  # @return [Mail::Message]
  def reminder_alert(address:, content:)
    @content = content
    mail(
      to: address,
      subject: "Reminder: #{content.title} (#{content.time_until_start_label})"
    )
  end

  # Sends a reminder alert from serializable primitives (for deliver_later).
  #
  # @param address [String] target email address
  # @param title [String]
  # @param time_until_start_label [String]
  # @param starts_at [String, nil] ISO8601 string
  # @param location [String, nil]
  # @param description [String, nil]
  # @return [Mail::Message]
  def reminder_alert_from_hash(address:, title:, time_until_start_label:, starts_at: nil,
                               location: nil, description: nil)
    @content = OpenStruct.new( # rubocop:disable Style/OpenStructUse
      title: title,
      time_until_start_label: time_until_start_label,
      starts_at: starts_at,
      location: location,
      description: description
    )
    mail(
      to: address,
      subject: "Reminder: #{title} (#{time_until_start_label})"
    )
  end
end
