# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: createSharedNotificationChannel', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_shared_channels:write') }
  let(:user) { create(:user, role: role) }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation Create($name: String!, $channelType: String!, $config: JSON!) {
        createSharedNotificationChannel(name: $name, channelType: $channelType, config: $config) {
          sharedNotificationChannel { id name channelType active }
          errors
        }
      }
    GQL
  end

  context 'when admin has the permission' do
    before { role.permissions << write_perm }

    it 'creates a shared channel' do
      variables = { name: 'Company ntfy', channelType: 'ntfy',
                    config: { base_url: 'https://ntfy.example.com', topic: 'company' } }
      post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
      json = JSON.parse(response.body)
      data = json['data']['createSharedNotificationChannel']
      expect(data['errors']).to eq []
      expect(data['sharedNotificationChannel']['name']).to eq 'Company ntfy'
    end
  end

  context 'when the user lacks the permission' do
    it 'returns NOT_AUTHORIZED' do
      variables = { name: 'Channel', channelType: 'ntfy', config: {} }
      post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to eq 'NOT_AUTHORIZED'
      expect(json['errors'].first['extensions']['code']).to eq 'UNAUTHORIZED'
    end
  end
end
