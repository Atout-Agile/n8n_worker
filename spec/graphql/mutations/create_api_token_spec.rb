# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::CreateApiToken, type: :request do
  let(:role) { create(:role) }
  let!(:tokens_write_perm) { create(:permission, :tokens_write) }
  let(:user) { create(:user, role: role) }

  before { role.permissions << tokens_write_perm }

  let(:query) do
    <<~GQL
      mutation CreateApiToken($name: String!, $expiresInDays: Int) {
        createApiToken(name: $name, expiresInDays: $expiresInDays) {
          apiToken {
            id
            name
            token
            expiresAt
            active
            user {
              email
            }
          }
          errors
        }
      }
    GQL
  end

  describe 'createApiToken mutation' do
    context 'when user is authenticated with tokens:write' do
      let(:token) { JsonWebToken.encode(user_id: user.id) }
      let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

      context 'with valid parameters' do
        let(:variables) { { name: 'Mon Token API' } }

        it 'creates a new API token' do
          expect {
            post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
          }.to change(ApiToken, :count).by(1)

          json = JSON.parse(response.body)
          data = json['data']['createApiToken']

          expect(data['errors']).to be_empty
          expect(data['apiToken']).to be_present
          expect(data['apiToken']['name']).to eq('Mon Token API')
          expect(data['apiToken']['token']).to be_present
          expect(data['apiToken']['active']).to be true
          expect(data['apiToken']['user']['email']).to eq(user.email)
        end

        it 'sets default expiration to 30 days' do
          post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers

          json = JSON.parse(response.body)
          expires_at = Time.zone.parse(json['data']['createApiToken']['apiToken']['expiresAt'])
          expect(expires_at).to be_within(1.minute).of(30.days.from_now)
        end

        it 'respects custom expiration' do
          custom_variables = { name: 'Mon Token API', expiresInDays: 7 }

          post '/graphql',
               params: { query: query, variables: custom_variables }.to_json,
               headers: headers

          json = JSON.parse(response.body)
          expires_at = Time.zone.parse(json['data']['createApiToken']['apiToken']['expiresAt'])
          expect(expires_at).to be_within(1.minute).of(7.days.from_now)
        end
      end

      context 'with invalid parameters' do
        let(:variables) { { name: '' } }

        it 'returns validation errors' do
          expect {
            post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
          }.not_to change(ApiToken, :count)

          json = JSON.parse(response.body)
          data = json['data']['createApiToken']

          expect(data['apiToken']).to be_nil
          expect(data['errors']).to include(match(/can't be blank/i))
        end
      end

      context 'with duplicate name' do
        let!(:existing_token) { create(:api_token, user: user, name: 'Mon Token API') }
        let(:variables) { { name: 'Mon Token API' } }

        it 'returns uniqueness error' do
          expect {
            post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
          }.not_to change(ApiToken, :count)

          json = JSON.parse(response.body)
          data = json['data']['createApiToken']

          expect(data['apiToken']).to be_nil
          expect(data['errors']).to include(match(/already have a token with this name/i))
        end
      end
    end

    context 'with permissionIds' do
      let!(:tokens_read_perm) { create(:permission, :tokens_read) }
      let!(:users_read_perm)  { create(:permission, :users_read) }

      let(:query_with_perms) do
        <<~GQL
          mutation CreateTokenWithPerms($name: String!, $permissionIds: [ID!]) {
            createApiToken(name: $name, permissionIds: $permissionIds) {
              apiToken { id permissions { name } }
              errors
            }
          }
        GQL
      end

      before { role.permissions << tokens_read_perm }

      it 'assigns in-role permissions to the created token' do
        token = JsonWebToken.encode(user_id: user.id)
        headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
        post '/graphql',
          params: { query: query_with_perms, variables: { name: 'Scoped', permissionIds: [tokens_read_perm.id.to_s] } }.to_json,
          headers: headers

        names = JSON.parse(response.body).dig('data', 'createApiToken', 'apiToken', 'permissions').map { |p| p['name'] }
        expect(names).to contain_exactly('tokens:read')
      end

      it 'ignores permission IDs outside the role' do
        token = JsonWebToken.encode(user_id: user.id)
        headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
        post '/graphql',
          params: { query: query_with_perms, variables: { name: 'Scoped', permissionIds: [users_read_perm.id.to_s] } }.to_json,
          headers: headers

        perms = JSON.parse(response.body).dig('data', 'createApiToken', 'apiToken', 'permissions')
        expect(perms).to be_empty
      end
    end

    context 'when user is not authenticated' do
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:variables) { { name: 'Mon Token API' } }

      it 'returns NOT_AUTHORIZED' do
        expect {
          post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
        }.not_to change(ApiToken, :count)

        json = JSON.parse(response.body)
        expect(json['data']['createApiToken']).to be_nil
        expect(json['errors'].first['message']).to eq('NOT_AUTHORIZED')
        expect(json['errors'].first['extensions']['code']).to eq('UNAUTHORIZED')
      end
    end

    context 'with invalid token' do
      let(:headers) { { 'Authorization' => 'Bearer invalid_token', 'Content-Type' => 'application/json' } }
      let(:variables) { { name: 'Mon Token API' } }

      it 'returns NOT_AUTHORIZED' do
        expect {
          post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
        }.not_to change(ApiToken, :count)

        json = JSON.parse(response.body)
        expect(json['data']['createApiToken']).to be_nil
        expect(json['errors'].first['message']).to eq('NOT_AUTHORIZED')
      end
    end
  end
end
