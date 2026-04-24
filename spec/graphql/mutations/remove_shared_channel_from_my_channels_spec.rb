# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: removeSharedChannelFromMyChannels', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let!(:shared) { create(:shared_notification_channel) }

  let(:query) do
    <<~GQL
      mutation Remove($id: ID!) {
        removeSharedChannelFromMyChannels(sharedChannelId: $id) { removed errors }
      }
    GQL
  end

  it 'destroys the personal channel record' do
    channel = create(:notification_channel, :shared, user: user, shared_notification_channel: shared)
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['removeSharedChannelFromMyChannels']['removed']).to be true
    expect(NotificationChannel.exists?(channel.id)).to be false
  end

  it 'returns not found if no personal channel exists' do
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['removeSharedChannelFromMyChannels']['errors']).to include('not found')
  end
end
