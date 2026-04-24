# frozen_string_literal: true

# Sets or updates the current user's calendar source URL.
# Only ICS sources are supported in S1.
#
# @example GraphQL usage
#   mutation {
#     setCalendarSource(url: "https://calendar.example.com/feed.ics") {
#       assistantConfig { calendarSourceUrl }
#       errors
#     }
#   }
#
# @since 2026-04-11
module Mutations
  class SetCalendarSource < BaseMutation
    permission_required "assistant_config:write"

    argument :url, String, required: true, description: "HTTPS URL of the ICS feed"

    field :assistant_config, Types::UserAssistantConfigType, null: true
    field :errors, [ String ], null: false

    # @param url [String]
    # @return [Hash]
    def resolve(url:)
      authorize! current_user, to: :write?, with: UserAssistantConfigPolicy

      config = current_user.assistant_config || current_user.build_assistant_config
      config.calendar_source_type = "ics"
      config.calendar_source_url = url

      if config.save
        { assistant_config: config, errors: [] }
      else
        { assistant_config: nil, errors: config.errors.full_messages }
      end
    end
  end
end
