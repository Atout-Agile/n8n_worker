# frozen_string_literal: true

require "icalendar"

module Assistant
  # Parses a raw ICS text payload into an array of ParsedEvent values.
  # Expands recurring events into concrete occurrences up to a
  # configurable horizon (default: 90 days from now).
  #
  # Recurrence is expanded manually from the RRULE data using the
  # +Icalendar::Values::Recur+ struct — the optional icalendar-recurrence
  # gem is not required.
  #
  # @see Assistant::ParsedEvent
  # @see Assistant::IcsFetcher
  # @since 2026-04-11
  class IcsParser
    FREQ_STEP = {
      "DAILY" => 1.day,
      "WEEKLY" => 1.week,
      "MONTHLY" => 1.month,
      "YEARLY" => 1.year
    }.freeze

    # @param raw [String] raw ICS feed text
    # @param horizon [Time] upper bound for recurrence expansion
    # @return [Array<ParsedEvent>]
    def parse(raw, horizon: 90.days.from_now)
      calendars = Icalendar::Calendar.parse(raw.to_s)
      events = []

      calendars.each do |calendar|
        calendar.events.each do |vevent|
          next if vevent.uid.blank? || vevent.dtstart.nil? || vevent.dtend.nil?

          occurrences = expand_occurrences(vevent, horizon)
          occurrences.each_with_index do |occ, idx|
            events << build_parsed_event(vevent, occ, idx)
          end
        end
      end

      events
    rescue StandardError => e
      Rails.logger.warn("Assistant::IcsParser failed: #{e.class}: #{e.message}")
      []
    end

    private

    def expand_occurrences(vevent, horizon)
      all_day = date_only?(vevent.dtstart)
      start_utc = normalize_time(vevent.dtstart, all_day)
      end_utc   = normalize_time(vevent.dtend, all_day)
      duration  = end_utc - start_utc

      if vevent.rrule.present? && vevent.rrule.any?
        expand_rrule(vevent.rrule.first, start_utc, duration, horizon)
      else
        [ { start: start_utc, end: end_utc } ]
      end
    end

    # Expand a single RRULE using FREQ/INTERVAL/COUNT/UNTIL.
    # Handles DAILY, WEEKLY, MONTHLY, YEARLY.
    #
    # @param rrule [Icalendar::Values::Recur]
    # @param start_utc [Time] first occurrence start in UTC
    # @param duration [Float] seconds between start and end
    # @param horizon [Time] upper bound
    # @return [Array<Hash>]
    def expand_rrule(rrule, start_utc, duration, horizon)
      step = FREQ_STEP[rrule.frequency.to_s.upcase]
      return [] unless step

      interval = [ rrule.interval.to_i, 1 ].max
      count_limit = rrule.count&.to_i
      until_limit = rrule.until&.to_time&.utc

      occurrences = []
      current = start_utc

      loop do
        break if current > horizon
        break if until_limit && current > until_limit
        break if count_limit && occurrences.size >= count_limit

        occurrences << { start: current, end: current + duration }
        current = current + (step * interval)
      end

      occurrences
    end

    def build_parsed_event(vevent, occurrence, index)
      base_uid = vevent.uid.to_s
      uid = index.zero? ? base_uid : "#{base_uid}##{occurrence[:start].utc.iso8601}"
      all_day = date_only?(vevent.dtstart) && date_only?(vevent.dtend)

      ParsedEvent.new(
        external_uid: uid,
        title: vevent.summary.to_s,
        starts_at: occurrence[:start].utc,
        ends_at: occurrence[:end].utc,
        location: vevent.location.to_s.presence,
        description: vevent.description.to_s.presence,
        source_last_modified: vevent.last_modified&.to_time&.utc,
        all_day: all_day,
        raw_payload: vevent.to_ical
      )
    end

    # Converts an icalendar date/datetime value to UTC.
    # For date-only values (all-day), builds UTC midnight from the date
    # components to avoid local-timezone offset pollution.
    #
    # @param ical_value [Icalendar::Values::Date, Icalendar::Values::DateTime, ActiveSupport::TimeWithZone]
    # @param all_day [Boolean]
    # @return [Time]
    def normalize_time(ical_value, all_day)
      if all_day
        d = ical_value.to_date
        Time.utc(d.year, d.month, d.day)
      else
        ical_value.to_time.utc
      end
    end

    def date_only?(ical_value)
      ical_value.is_a?(Icalendar::Values::Date)
    end
  end
end
