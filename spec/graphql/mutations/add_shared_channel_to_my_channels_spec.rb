# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: addSharedChannelToMyChannels', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let!(:shared) { create(:shared_notification_channel) }

  let(:add_mutation) do
    <<~GQL
      mutation Add($id: ID!) {
        addSharedChannelToMyChannels(sharedChannelId: $id) {
          notificationChannel { active channelType }
          errors
        }
      }
    GQL
  end

  let(:ack_mutation) do
    <<~GQL
      mutation Ack($id: ID!) {
        acknowledgeSharedChannelConsent(sharedChannelId: $id) {
          acknowledgedAt
          errors
        }
      }
    GQL
  end

  it 'refuses to activate before consent is acknowledged' do
    post '/graphql',
         params: { query: add_mutation, variables: { id: shared.id.to_s } }.to_json,
         headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['addSharedChannelToMyChannels']['errors'].join).to include('consent')
  end

  it 'activates after consent is acknowledged' do
    post '/graphql', params: { query: ack_mutation, variables: { id: shared.id.to_s } }.to_json, headers: headers
    post '/graphql', params: { query: add_mutation, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['addSharedChannelToMyChannels']
    expect(data['errors']).to eq []
    expect(data['notificationChannel']['active']).to be true
  end
end
