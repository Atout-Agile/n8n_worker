# frozen_string_literal: true

require "net/http"
require "uri"

module Assistant
  module Channels
    # Posts the alert to a ntfy HTTP endpoint. Uses the topic URL
    # `base_url/topic` with the title as the "Title" header and the
    # default text body as the request body.
    #
    # @see Assistant::Channels::BaseAdapter
    # @since 2026-04-11
    class NtfyAdapter < BaseAdapter
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10

      def emit(content:, reminder:)
        _ = reminder
        uri = URI.parse("#{channel.config["base_url"]}/#{channel.config["topic"]}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.is_a?(URI::HTTPS)
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        request = Net::HTTP::Post.new(uri.request_uri)
        request["Title"] = content.title.to_s
        request["Content-Type"] = "text/plain; charset=utf-8"
        request.body = content.default_text_body

        response = http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          Result.new(status: :success)
        else
          Result.new(status: :failed, error: "HTTP #{response.code}")
        end
      rescue StandardError => e
        Result.new(status: :failed, error: e.message)
      end
    end
  end
end
