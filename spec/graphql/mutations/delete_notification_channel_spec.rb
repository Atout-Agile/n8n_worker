# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: deleteNotificationChannel', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation Del($id: ID!) {
        deleteNotificationChannel(id: $id) { deletedId errors }
      }
    GQL
  end

  it 'deletes a channel owned by the user' do
    channel = create(:notification_channel, :ntfy, :active, user: user)
    post '/graphql', params: { query: query, variables: { id: channel.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['deleteNotificationChannel']['errors']).to eq []
    expect(NotificationChannel.exists?(channel.id)).to be false
  end

  it 'returns an error when the id is not found among the user channels' do
    other_user = create(:user, role: role)
    other_channel = create(:notification_channel, :ntfy, :active, user: other_user)
    post '/graphql', params: { query: query, variables: { id: other_channel.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['deleteNotificationChannel']['errors']).to include('not found')
  end
end
