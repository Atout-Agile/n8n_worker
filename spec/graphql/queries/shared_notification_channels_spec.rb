# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: sharedNotificationChannels', type: :request do
  let(:role) { create(:role, :user) }
  let!(:read_perm) { create(:permission, name: 'assistant_shared_channels:read') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << read_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      query {
        sharedNotificationChannels { id name channelType active }
      }
    GQL
  end

  it 'returns active shared channels' do
    active   = create(:shared_notification_channel, active: true)
    inactive = create(:shared_notification_channel, active: false)
    post '/graphql', params: { query: query }.to_json, headers: headers
    json = JSON.parse(response.body)
    ids = json['data']['sharedNotificationChannels'].map { |c| c['id'] }
    expect(ids).to include(active.id.to_s)
    expect(ids).not_to include(inactive.id.to_s)
  end
end
