# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 1, email: 'test@example.com' } }
  let(:token) { described_class.encode(payload) }

  describe '.encode' do
    it 'encodes payload into JWT token' do
      expect(token).to be_a(String)
      expect(token.split('.')).to match_array([be_a(String), be_a(String), be_a(String)])
    end

    it 'adds expiration to payload' do
      decoded = described_class.decode(token)
      expect(decoded[:exp]).to be_present
    end
  end

  describe '.decode' do
    it 'decodes valid token' do
      decoded = described_class.decode(token)
      expect(decoded[:user_id]).to eq(payload[:user_id])
      expect(decoded[:email]).to eq(payload[:email])
    end

    it 'raises error for invalid token' do
      expect {
        described_class.decode('invalid.token.here')
      }.to raise_error(JWT::VerificationError)
    end

    it 'raises error for expired token' do
      expired_token = described_class.encode(payload.merge(exp: 1.day.ago.to_i))
      expect {
        described_class.decode(expired_token)
      }.to raise_error(JWT::VerificationError, /expired/)
    end
  end
end 