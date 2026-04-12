# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Assistant
  module Channels
    # Posts a JSON payload describing the alert to a user-provided
    # webhook URL. The payload is intentionally flat and versioned.
    #
    # @since 2026-04-11
    class WebhookAdapter < BaseAdapter
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10
      PAYLOAD_VERSION = 1

      def emit(content:, reminder:)
        _ = reminder
        uri = URI.parse(channel.config["url"])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.is_a?(URI::HTTPS)
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        request = Net::HTTP::Post.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = build_payload(content).to_json

        response = http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          Result.new(status: :success)
        else
          Result.new(status: :failed, error: "HTTP #{response.code}")
        end
      rescue StandardError => e
        Result.new(status: :failed, error: e.message)
      end

      private

      def build_payload(content)
        {
          "version" => PAYLOAD_VERSION,
          "title" => content.title,
          "offset_minutes" => content.offset_minutes,
          "time_until_start" => content.time_until_start_label,
          "starts_at" => content.starts_at&.utc&.iso8601,
          "ends_at" => content.ends_at&.utc&.iso8601,
          "location" => content.location,
          "description" => content.description,
          "external_uid" => content.external_uid
        }
      end
    end
  end
end
