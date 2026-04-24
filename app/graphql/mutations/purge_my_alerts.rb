# frozen_string_literal: true

# Purges the current user's alert emission history. Accepts an
# optional "before" timestamp (purge everything older) or specific ids.
# Requires the +assistant_alerts:write+ permission.
#
# @since 2026-04-11
module Mutations
  class PurgeMyAlerts < BaseMutation
    permission_required "assistant_alerts:write"

    argument :before, GraphQL::Types::ISO8601DateTime, required: false
    argument :ids, [ ID ], required: false

    field :purged_count, Int, null: false
    field :errors, [ String ], null: false

    # @param before [Time, nil]
    # @param ids [Array<String>, nil]
    # @return [Hash]
    def resolve(before: nil, ids: nil)
      authorize! current_user, to: :write?, with: AlertEmissionPolicy

      scope = current_user.alert_emissions
      scope = scope.where("emitted_at < ?", before) if before
      scope = scope.where(id: ids) if ids&.any?
      count = scope.delete_all
      { purged_count: count, errors: [] }
    end
  end
end
