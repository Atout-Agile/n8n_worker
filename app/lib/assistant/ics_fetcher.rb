# frozen_string_literal: true

require "net/http"
require "uri"

module Assistant
  # Fetches an ICS feed over HTTPS with a short timeout. Returns a
  # simple Result object so callers can handle failure without
  # exception handling.
  #
  # @example
  #   result = Assistant::IcsFetcher.new.fetch('https://calendar.example.com/feed.ics')
  #   return result.body if result.success?
  #
  # @see Assistant::IcsParser
  # @see Assistant::EventReconciler
  # @since 2026-04-11
  class IcsFetcher
    Result = Struct.new(:body, :error, keyword_init: true) do
      def success?
        error.nil?
      end
    end

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    # @param url [String]
    # @return [Result]
    def fetch(url)
      uri = URI.parse(url)
      return Result.new(body: nil, error: "url must use HTTPS") unless uri.is_a?(URI::HTTPS)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      if response.is_a?(Net::HTTPSuccess)
        Result.new(body: response.body, error: nil)
      else
        Result.new(body: nil, error: "HTTP #{response.code}")
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Result.new(body: nil, error: "timeout: #{e.message}")
    rescue StandardError => e
      Result.new(body: nil, error: e.message)
    end
  end
end
