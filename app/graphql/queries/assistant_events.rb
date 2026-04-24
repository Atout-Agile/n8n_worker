# frozen_string_literal: true

# Lists the current user's known calendar events within a time window.
#
# @example
#   { assistantEvents(from: "2026-04-01T00:00:00Z", to: "2026-04-30T23:59:59Z") { id title startsAt } }
#
# @since 2026-04-11
module Queries
  class AssistantEvents < Queries::BaseQuery
    permission_required "assistant_config:read"

    argument :from, GraphQL::Types::ISO8601DateTime, required: true
    argument :to,   GraphQL::Types::ISO8601DateTime, required: true
    argument :limit, Int, required: false, default_value: 200

    type [ Types::CalendarEventType ], null: false

    # @param from [Time]
    # @param to [Time]
    # @param limit [Integer]
    # @return [ActiveRecord::Relation]
    def resolve(from:, to:, limit:)
      authorize! current_user, to: :read?, with: CalendarEventPolicy
      current_user.calendar_events
                  .scheduled_scope
                  .where(starts_at: from..to)
                  .order(starts_at: :asc)
                  .limit([ limit, 500 ].min)
    end
  end
end
