# frozen_string_literal: true

# Returns the current user's alert emission history (internal channel A).
# Requires the +assistant_alerts:read+ permission.
#
# @since 2026-04-11
module Queries
  class AssistantAlerts < Queries::BaseQuery
    permission_required "assistant_alerts:read"

    argument :limit, Int, required: false, default_value: 100
    argument :before, GraphQL::Types::ISO8601DateTime, required: false

    type [ Types::AlertEmissionType ], null: false

    # @param limit [Integer]
    # @param before [Time, nil]
    # @return [ActiveRecord::Relation]
    def resolve(limit:, before: nil)
      authorize! current_user, to: :read?, with: AlertEmissionPolicy
      scope = current_user.alert_emissions.order(emitted_at: :desc).limit([ limit, 500 ].min)
      scope = scope.where("emitted_at < ?", before) if before
      scope
    end
  end
end
