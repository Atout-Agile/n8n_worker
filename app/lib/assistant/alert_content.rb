# frozen_string_literal: true

module Assistant
  # Immutable value wrapping an alert's frozen content snapshot.
  # Channel adapters receive an AlertContent instead of the raw
  # CalendarReminder so they are decoupled from the storage model.
  #
  # @see Assistant::ReminderPlanner
  # @see Assistant::Channels::BaseAdapter
  # @since 2026-04-11
  class AlertContent
    attr_reader :event_id, :external_uid, :title, :location, :description,
                :starts_at, :ends_at, :offset_minutes

    # @param snapshot [Hash]
    # @param offset_minutes [Integer]
    # @return [AlertContent]
    def self.from_reminder_snapshot(snapshot, offset_minutes:)
      data = snapshot || {}
      new(
        event_id: data["event_id"],
        external_uid: data["external_uid"],
        title: data["title"],
        location: data["location"],
        description: data["description"],
        starts_at: parse_time(data["starts_at"]),
        ends_at: parse_time(data["ends_at"]),
        offset_minutes: offset_minutes
      )
    end

    # @param value [String, nil]
    # @return [Time, nil]
    def self.parse_time(value)
      return nil if value.blank?

      Time.iso8601(value)
    rescue ArgumentError
      nil
    end

    def initialize(event_id:, external_uid:, title:, location:, description:, starts_at:, ends_at:, offset_minutes:)
      @event_id = event_id
      @external_uid = external_uid
      @title = title
      @location = location
      @description = description
      @starts_at = starts_at
      @ends_at = ends_at
      @offset_minutes = offset_minutes
      freeze
    end

    # @return [String]
    def time_until_start_label
      minutes = offset_minutes.to_i
      if minutes.zero?
        "now"
      elsif minutes < 60
        "in #{minutes} min"
      else
        hours = minutes / 60
        remainder = minutes % 60
        remainder.zero? ? "in #{hours} h" : "in #{hours} h #{remainder} min"
      end
    end

    # Short one-line summary used by simple text channels.
    #
    # @return [String]
    def short_summary
      "#{title} #{time_until_start_label}"
    end

    # Multi-line plain text body for email / webhook / internal log.
    #
    # @return [String]
    def default_text_body
      lines = []
      lines << title
      lines << "Starts: #{starts_at.utc.iso8601} (#{time_until_start_label})" if starts_at
      lines << "Location: #{location}" if location.present?
      lines << ""
      lines << description if description.present?
      lines.join("\n")
    end
  end
end
