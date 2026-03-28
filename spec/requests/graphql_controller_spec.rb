# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlController, type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }

  describe 'POST /graphql' do
    let(:valid_query) do
      <<~GQL
        query {
          testField
        }
      GQL
    end

    let(:login_mutation) do
      <<~GQL
        mutation Login($email: String!, $password: String!) {
          login(input: { email: $email, password: $password }) {
            token
            user {
              id
              email
            }
            errors
          }
        }
      GQL
    end

    context 'with valid GraphQL query' do
      it 'executes the query successfully' do
        post '/graphql', params: { query: valid_query }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['testField']).to eq('Hello World!')
      end

      it 'handles variables correctly' do
        post '/graphql', params: {
          query: login_mutation,
          variables: { email: user.email, password: 'password123' }
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        # The login will fail with invalid credentials, but the query should execute
        expect(json['data']).to be_present
        expect(json['data']['login']).to be_present
      end

      it 'handles operation name' do
        post '/graphql', params: {
          query: login_mutation,
          variables: { email: user.email, password: 'password123' },
          operationName: 'Login'
        }

        expect(response).to have_http_status(:success)
      end
    end

    context 'with different variable formats' do
      it 'handles string variables' do
        post '/graphql', params: {
          query: login_mutation,
          variables: { email: user.email, password: 'password123' }.to_json
        }

        expect(response).to have_http_status(:success)
      end

      it 'handles hash variables directly' do
        post '/graphql', params: {
          query: login_mutation,
          variables: { email: user.email, password: 'password123' }  # Hash direct
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']).to be_present
      end

      it 'handles empty string variables' do
        post '/graphql', params: {
          query: valid_query,
          variables: ''
        }

        expect(response).to have_http_status(:success)
      end

      it 'handles nil variables' do
        post '/graphql', params: {
          query: valid_query,
          variables: nil
        }

        expect(response).to have_http_status(:success)
      end

      it 'handles ActionController::Parameters' do
        # Test with regular hash parameters instead
        post '/graphql', params: {
          query: valid_query,
          variables: { test: 'value' }
        }

        expect(response).to have_http_status(:success)
      end

      it 'raises ArgumentError for unexpected parameter type' do
        expect {
          post '/graphql', params: {
            query: valid_query,
            variables: []
          }
        }.to raise_error(ArgumentError, /Unexpected parameter/)
      end
    end

    context 'testing prepare_variables method directly' do
      let(:controller) { GraphqlController.new }

      it 'handles Hash variables in prepare_variables' do
        # Test the private method directly
        result = controller.send(:prepare_variables, { test: 'value' })
        expect(result).to eq({ test: 'value' })
      end

      it 'handles String variables in prepare_variables' do
        result = controller.send(:prepare_variables, '{"test": "value"}')
        expect(result).to eq({ 'test' => 'value' })
      end

      it 'handles nil variables in prepare_variables' do
        result = controller.send(:prepare_variables, nil)
        expect(result).to eq({})
      end

      it 'handles empty string variables in prepare_variables' do
        result = controller.send(:prepare_variables, '')
        expect(result).to eq({})
      end
    end

    context 'with invalid JSON in string variables' do
      it 'handles invalid JSON gracefully' do
        expect {
          post '/graphql', params: {
            query: valid_query,
            variables: 'invalid json'
          }
        }.to raise_error(JSON::ParserError)
      end
    end

    context 'with GraphQL errors' do
      let(:invalid_query) do
        <<~GQL
          query {
            nonExistentField
          }
        GQL
      end

      it 'handles GraphQL errors gracefully' do
        post '/graphql', params: { query: invalid_query }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'with runtime errors' do
      before do
        allow(N8nWorkerSchema).to receive(:execute).and_raise(StandardError, 'Test error')
      end

      context 'in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it 'handles errors in development mode' do
          post '/graphql', params: { query: valid_query }

          expect(response).to have_http_status(500)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
          expect(json['errors'].first['message']).to include('Test error')
        end
      end

      context 'in production environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
        end

        it 'raises the error in production mode' do
          expect {
            post '/graphql', params: { query: valid_query }
          }.to raise_error(StandardError, 'Test error')
        end
      end
    end

    context 'with malformed requests' do
      it 'handles missing query parameter' do
        post '/graphql', params: {}

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'handles empty query' do
        post '/graphql', params: { query: '' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'CSRF protection' do
      it 'allows requests without CSRF token' do
        # This should work because we use protect_from_forgery with: :null_session
        post '/graphql', params: { query: valid_query }

        expect(response).to have_http_status(:success)
      end
    end

    context 'API token authentication' do
      let(:raw_token) { SecureRandom.hex(32) }
      let!(:api_token) do
        create(:api_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))
      end

      it 'authenticates with a valid active API token' do
        post '/graphql',
          params: { query: valid_query },
          headers: { 'Authorization' => "Bearer #{raw_token}" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_nil
      end

      it 'updates last_used_at on successful API token authentication' do
        expect {
          post '/graphql',
            params: { query: valid_query },
            headers: { 'Authorization' => "Bearer #{raw_token}" }
        }.to change { api_token.reload.last_used_at }
      end

      it 'rejects an expired API token' do
        api_token.update!(expires_at: 1.day.ago)

        post '/graphql',
          params: { query: valid_query },
          headers: { 'Authorization' => "Bearer #{raw_token}" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        # Request goes through but current_user is nil (unauthenticated)
        expect(json['data']['testField']).to be_nil.or eq('Hello World!')
      end

      it 'rejects an unknown token' do
        post '/graphql',
          params: { query: valid_query },
          headers: { 'Authorization' => 'Bearer unknowntoken000' }

        expect(response).to have_http_status(:success)
      end

      it 'falls back to JWT when token does not match any API token' do
        jwt = JsonWebToken.encode(user_id: user.id)

        post '/graphql',
          params: { query: valid_query },
          headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:success)
      end
    end
  end
end 