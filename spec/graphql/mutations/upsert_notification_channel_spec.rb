# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: upsertNotificationChannel', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation Upsert($type: String!, $config: JSON!) {
        upsertNotificationChannel(type: $type, active: true, config: $config) {
          notificationChannel { id channelType active }
          errors
        }
      }
    GQL
  end

  it 'creates a ntfy channel' do
    variables = { type: 'ntfy', config: { base_url: 'https://ntfy.example.com', topic: 'user-1' } }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['upsertNotificationChannel']
    expect(data['errors']).to eq []
    expect(data['notificationChannel']['channelType']).to eq 'ntfy'
  end

  it 'refuses to create a shared channel' do
    variables = { type: 'shared', config: {} }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['upsertNotificationChannel']['errors'].join).to include('addSharedChannelToMyChannels')
  end
end
