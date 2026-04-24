# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: deleteSharedNotificationChannel', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_shared_channels:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let!(:shared) { create(:shared_notification_channel) }

  let(:query) do
    <<~GQL
      mutation Del($id: ID!) {
        deleteSharedNotificationChannel(id: $id) { deletedId errors }
      }
    GQL
  end

  it 'deletes an unreferenced shared channel' do
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['deleteSharedNotificationChannel']
    expect(data['errors']).to eq []
    expect(SharedNotificationChannel.exists?(shared.id)).to be false
  end

  it 'fails when a personal channel still references it (dependent: :restrict_with_error)' do
    create(:notification_channel, :shared, user: user, shared_notification_channel: shared)
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['deleteSharedNotificationChannel']['errors']).not_to be_empty
    expect(SharedNotificationChannel.exists?(shared.id)).to be true
  end
end
