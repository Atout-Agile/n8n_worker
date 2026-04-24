# frozen_string_literal: true

# Sends assistant reminder emails.
#
# @see Assistant::Channels::EmailAdapter
# @see Assistant::AlertContent
# @since 2026-04-11
class AssistantMailer < ApplicationMailer
  default from: "assistant@localhost"

  # Sends one reminder alert email from plain primitive arguments.
  # All temporal fields must be pre-serialised to ISO8601 strings so this
  # method is safe to call via +deliver_later+ (Active Job cannot serialize
  # arbitrary Ruby objects like +Time+ or custom structs).
  #
  # @param address [String] target email address
  # @param title [String] event title
  # @param time_until_start_label [String] human-readable countdown label
  # @param starts_at [String, nil] ISO8601 string (already formatted by caller)
  # @param ends_at [String, nil] ISO8601 string (already formatted by caller)
  # @param location [String, nil] optional location string
  # @param description [String, nil] optional event description
  # @return [Mail::Message]
  # @example
  #   AssistantMailer.reminder_alert(
  #     address: "user@example.com",
  #     title: "Dentist",
  #     time_until_start_label: "in 15 min",
  #     starts_at: "2026-06-12T14:00:00Z"
  #   ).deliver_later
  def reminder_alert(address:, title:, time_until_start_label:,
                     starts_at: nil, ends_at: nil, location: nil, description: nil)
    @content = OpenStruct.new( # rubocop:disable Style/OpenStructUse
      title: title,
      time_until_start_label: time_until_start_label,
      starts_at: starts_at,
      ends_at: ends_at,
      location: location,
      description: description
    )
    mail(
      to: address,
      subject: "Reminder: #{title} (#{time_until_start_label})"
    )
  end
end
