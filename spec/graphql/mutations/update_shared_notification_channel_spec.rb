# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: updateSharedNotificationChannel', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_shared_channels:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let!(:shared) { create(:shared_notification_channel, name: 'Old Name') }

  let(:query) do
    <<~GQL
      mutation Update($id: ID!, $name: String) {
        updateSharedNotificationChannel(id: $id, name: $name) {
          sharedNotificationChannel { id name }
          errors
        }
      }
    GQL
  end

  it 'updates the channel name' do
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s, name: 'New Name' } }.to_json,
                     headers: headers
    json = JSON.parse(response.body)
    data = json['data']['updateSharedNotificationChannel']
    expect(data['errors']).to eq []
    expect(data['sharedNotificationChannel']['name']).to eq 'New Name'
  end

  it 'returns not found for a missing id' do
    post '/graphql', params: { query: query, variables: { id: '999999', name: 'X' } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['updateSharedNotificationChannel']['errors']).to include('not found')
  end
end
