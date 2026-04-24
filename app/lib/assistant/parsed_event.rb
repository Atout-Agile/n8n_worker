# frozen_string_literal: true

module Assistant
  # Immutable value object representing one event as seen in an ICS feed.
  # Times are UTC-normalized so downstream callers can convert to the
  # user's timezone at their leisure.
  #
  # @since 2026-04-11
  ParsedEvent = Struct.new(
    :external_uid,
    :title,
    :starts_at,
    :ends_at,
    :location,
    :description,
    :source_last_modified,
    :all_day,
    :raw_payload,
    keyword_init: true
  ) do
    # @return [Boolean]
    def all_day?
      all_day == true
    end
  end
end
