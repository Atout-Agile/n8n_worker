# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::IcsFetcher do
  let(:url) { 'https://calendar.example.com/secret.ics' }

  describe '#fetch' do
    it 'returns a success result with body on 200' do
      stub_request(:get, url).to_return(status: 200, body: "BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n")
      result = described_class.new.fetch(url)
      expect(result).to be_success
      expect(result.body).to include('VCALENDAR')
    end

    it 'returns a failure result on HTTP 500' do
      stub_request(:get, url).to_return(status: 500, body: 'boom')
      result = described_class.new.fetch(url)
      expect(result).not_to be_success
      expect(result.error).to include('HTTP 500')
    end

    it 'returns a failure result on timeout' do
      stub_request(:get, url).to_timeout
      result = described_class.new.fetch(url)
      expect(result).not_to be_success
      expect(result.error).to match(/timeout|timed out/i)
    end

    it 'returns a failure result on connection error' do
      stub_request(:get, url).to_raise(SocketError.new('getaddrinfo'))
      result = described_class.new.fetch(url)
      expect(result).not_to be_success
      expect(result.error).to include('getaddrinfo')
    end

    it 'rejects non-HTTPS URLs' do
      result = described_class.new.fetch('http://example.com/x.ics')
      expect(result).not_to be_success
      expect(result.error).to include('HTTPS')
    end
  end
end
