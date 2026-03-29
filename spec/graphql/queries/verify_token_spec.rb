# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::VerifyToken do
  let(:role)      { create(:role) }
  let!(:tokens_read_perm) { create(:permission, :tokens_read) }
  let(:user)      { create(:user, role: role) }
  let(:raw_token) { SecureRandom.hex(32) }
  let!(:api_token) do
    create(:api_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))
  end

  before { role.permissions << tokens_read_perm }

  let(:query) do
    <<~GQL
      query VerifyToken($token: String!) {
        verifyToken(token: $token) {
          id
          name
          active
          expiresAt
          lastUsedAt
          user {
            id
            email
          }
        }
      }
    GQL
  end

  def execute(token:, context_user: user)
    N8nWorkerSchema.execute(
      query,
      variables: { token: token },
      context: { current_user: context_user, current_token: nil }
    ).to_h
  end

  describe 'verifyToken query' do
    context 'with a valid active token' do
      it 'returns the token details' do
        result = execute(token: raw_token)

        data = result.dig('data', 'verifyToken')
        expect(data).not_to be_nil
        expect(data['id']).to eq(api_token.id.to_s)
        expect(data['name']).to eq(api_token.name)
        expect(data['active']).to be true
      end

      it 'returns the associated user' do
        result = execute(token: raw_token)

        user_data = result.dig('data', 'verifyToken', 'user')
        expect(user_data['id']).to eq(user.id.to_s)
        expect(user_data['email']).to eq(user.email)
      end
    end

    context 'with an expired token' do
      before { api_token.update!(expires_at: 1.day.ago) }

      it 'returns nil' do
        result = execute(token: raw_token)

        expect(result.dig('data', 'verifyToken')).to be_nil
      end
    end

    context 'with an unknown token' do
      it 'returns nil' do
        result = execute(token: SecureRandom.hex(32))

        expect(result.dig('data', 'verifyToken')).to be_nil
      end
    end

    context 'with a revoked token (expires_at set to now)' do
      before { api_token.update!(expires_at: Time.current) }

      it 'returns nil' do
        result = execute(token: raw_token)

        expect(result.dig('data', 'verifyToken')).to be_nil
      end
    end
  end
end
