# frozen_string_literal: true

# Updates the current user's assistant config (timezone + reminder intervals).
# Requires the +assistant_config:write+ permission.
#
# @example GraphQL usage
#   mutation {
#     updateAssistantConfig(timezone: "Europe/Paris", reminderIntervals: [60, 15, 5]) {
#       assistantConfig { id timezone reminderIntervals }
#       errors
#     }
#   }
#
# @see Types::UserAssistantConfigType
# @see UserAssistantConfigPolicy
# @since 2026-04-11
module Mutations
  class UpdateAssistantConfig < BaseMutation
    permission_required "assistant_config:write"

    argument :timezone, String, required: false
    argument :reminder_intervals, [ Int ], required: false

    field :assistant_config, Types::UserAssistantConfigType, null: true
    field :errors, [ String ], null: false

    # @param timezone [String, nil]
    # @param reminder_intervals [Array<Integer>, nil]
    # @return [Hash]
    def resolve(timezone: nil, reminder_intervals: nil)
      authorize! current_user, to: :write?, with: UserAssistantConfigPolicy

      config = current_user.assistant_config || current_user.build_assistant_config
      config.timezone = timezone if timezone
      config.reminder_intervals = reminder_intervals if reminder_intervals

      if config.save
        { assistant_config: config, errors: [] }
      else
        { assistant_config: nil, errors: config.errors.full_messages }
      end
    end
  end
end
