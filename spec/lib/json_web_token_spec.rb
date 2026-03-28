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

    context 'with custom JWT_EXPIRATION' do
      it 'uses custom expiration when set' do
        # Mock both ENV calls
        allow(ENV).to receive(:fetch).with('JWT_EXPIRATION', '24h').and_return('2h')
        allow(ENV).to receive(:fetch).with('JWT_SECRET_KEY').and_yield
        allow(Rails.application.credentials).to receive(:secret_key_base).and_return('test_secret')
        
        token = described_class.encode(payload)
        decoded = described_class.decode(token)
        
        # L'expiration devrait être dans environ 2 heures
        expected_exp = 2.hours.from_now.to_i
        expect(decoded[:exp]).to be_within(5).of(expected_exp)
      end
    end

    context 'with invalid expiration format' do
      it 'falls back to 24 hours when format is not recognized' do
        # Mock both ENV calls
        allow(ENV).to receive(:fetch).with('JWT_EXPIRATION', '24h').and_return('invalid_format')
        allow(ENV).to receive(:fetch).with('JWT_SECRET_KEY').and_yield
        allow(Rails.application.credentials).to receive(:secret_key_base).and_return('test_secret')
        
        token = described_class.encode(payload)
        decoded = described_class.decode(token)
        
        # Devrait utiliser le fallback de 24 heures
        expected_exp = 24.hours.from_now.to_i
        expect(decoded[:exp]).to be_within(5).of(expected_exp)
      end
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

  describe 'private methods' do
    describe '#secret_key' do
      context 'when JWT_SECRET_KEY is set' do
        it 'uses JWT_SECRET_KEY from environment' do
          allow(ENV).to receive(:fetch).with('JWT_SECRET_KEY').and_return('custom_secret')
          
          secret = described_class.send(:secret_key)
          expect(secret).to eq('custom_secret')
        end
      end

      context 'when JWT_SECRET_KEY is not set' do
        it 'falls back to Rails secret_key_base' do
          allow(ENV).to receive(:fetch).with('JWT_SECRET_KEY').and_yield
          allow(Rails.application.credentials).to receive(:secret_key_base).and_return('rails_secret')
          
          secret = described_class.send(:secret_key)
          expect(secret).to eq('rails_secret')
        end
      end
    end

    describe '#expiration_from_string' do
      it 'parses hours format correctly' do
        expiration = described_class.send(:expiration_from_string, '12h')
        expected = 12.hours.from_now.to_i
        expect(expiration).to be_within(5).of(expected)
      end

      it 'handles single digit hours' do
        expiration = described_class.send(:expiration_from_string, '1h')
        expected = 1.hour.from_now.to_i
        expect(expiration).to be_within(5).of(expected)
      end

      it 'falls back to 24 hours for invalid format' do
        expiration = described_class.send(:expiration_from_string, 'invalid')
        expected = 24.hours.from_now.to_i
        expect(expiration).to be_within(5).of(expected)
      end

      it 'falls back to 24 hours for empty string' do
        expiration = described_class.send(:expiration_from_string, '')
        expected = 24.hours.from_now.to_i
        expect(expiration).to be_within(5).of(expected)
      end

      it 'falls back to 24 hours for minutes format' do
        expiration = described_class.send(:expiration_from_string, '30m')
        expected = 24.hours.from_now.to_i
        expect(expiration).to be_within(5).of(expected)
      end
    end
  end
end 