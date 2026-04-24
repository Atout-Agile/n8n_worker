# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: assistantConfig query', type: :request do
  let(:role) { create(:role, :user) }
  let!(:read_perm) { create(:permission, name: 'assistant_config:read') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << read_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      query {
        assistantConfig {
          id
          timezone
          reminderIntervals
          calendarSourceUrl
        }
      }
    GQL
  end

  context 'when the user has permission' do
    it 'returns the current user config, creating it if absent' do
      post '/graphql', params: { query: query }.to_json, headers: headers
      json = JSON.parse(response.body)
      expect(json['errors']).to be_nil
      expect(json.dig('data', 'assistantConfig', 'timezone')).to eq 'UTC'
      expect(json.dig('data', 'assistantConfig', 'reminderIntervals')).to be_an(Array)
      expect(user.reload.assistant_config).to be_present
    end
  end

  context 'when the user lacks the permission' do
    # Share the same role (fixed name 'user') but create a user NOT added to permissions
    let(:unpermitted_role) { create(:role) }
    let(:other_user) { create(:user, role: unpermitted_role) }
    let(:jwt_token) { JsonWebToken.encode(user_id: other_user.id) }

    it 'returns NOT_AUTHORIZED' do
      post '/graphql', params: { query: query }.to_json, headers: headers
      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to eq 'NOT_AUTHORIZED'
      expect(json['errors'].first['extensions']['code']).to eq 'UNAUTHORIZED'
    end
  end
end
