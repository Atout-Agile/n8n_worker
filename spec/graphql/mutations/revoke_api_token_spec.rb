# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::RevokeApiToken do
  let(:role)  { create(:role) }
  let!(:tokens_write_perm) { create(:permission, :tokens_write) }
  let(:user)  { create(:user, role: role) }
  let!(:api_token) { create(:api_token, user: user) }

  before { role.permissions << tokens_write_perm }

  let(:mutation) do
    <<~GQL
      mutation RevokeApiToken($id: ID!) {
        revokeApiToken(id: $id) {
          success
          errors
        }
      }
    GQL
  end

  def execute(id:, current_user: user)
    N8nWorkerSchema.execute(
      mutation,
      variables: { id: id },
      context: { current_user: current_user, current_token: nil }
    ).to_h
  end

  describe 'revokeApiToken mutation' do
    context 'when user is authenticated with tokens:write' do
      it 'revokes the token successfully' do
        result = execute(id: api_token.id)

        expect(result.dig('data', 'revokeApiToken', 'success')).to be true
        expect(result.dig('data', 'revokeApiToken', 'errors')).to be_empty
      end

      it 'sets the token expiration to now, making it inactive' do
        execute(id: api_token.id)

        expect(api_token.reload.active?).to be false
      end

      it 'returns an error for a token belonging to another user' do
        other_user = create(:user, role: role)
        other_token = create(:api_token, user: other_user)

        result = execute(id: other_token.id)

        expect(result.dig('data', 'revokeApiToken', 'success')).to be false
        expect(result.dig('data', 'revokeApiToken', 'errors')).to include('Token not found')
      end

      it 'returns an error for a non-existent token id' do
        result = execute(id: -1)

        expect(result.dig('data', 'revokeApiToken', 'success')).to be false
        expect(result.dig('data', 'revokeApiToken', 'errors')).to include('Token not found')
      end
    end

    context 'when user is not authenticated' do
      it 'returns NOT_AUTHORIZED' do
        result = execute(id: api_token.id, current_user: nil)

        expect(result.dig('data', 'revokeApiToken')).to be_nil
        expect(result.dig('errors', 0, 'message')).to eq('NOT_AUTHORIZED')
        expect(result.dig('errors', 0, 'extensions', 'code')).to eq('UNAUTHORIZED')
      end
    end
  end
end
