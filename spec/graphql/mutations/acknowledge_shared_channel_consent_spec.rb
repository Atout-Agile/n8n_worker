# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: acknowledgeSharedChannelConsent', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let!(:shared) { create(:shared_notification_channel) }

  let(:query) do
    <<~GQL
      mutation Ack($id: ID!) {
        acknowledgeSharedChannelConsent(sharedChannelId: $id) {
          acknowledgedAt
          errors
        }
      }
    GQL
  end

  it 'records consent and creates an inactive channel row' do
    post '/graphql', params: { query: query, variables: { id: shared.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['acknowledgeSharedChannelConsent']
    expect(data['errors']).to eq []
    expect(data['acknowledgedAt']).not_to be_nil

    channel = user.notification_channels.find_by(shared_notification_channel_id: shared.id)
    expect(channel).to be_present
    expect(channel.active).to be false
    expect(channel.consent_acknowledged_at).not_to be_nil
  end

  it 'returns not found for an inactive shared channel' do
    inactive = create(:shared_notification_channel, active: false)
    post '/graphql', params: { query: query, variables: { id: inactive.id.to_s } }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['acknowledgeSharedChannelConsent']['errors']).to include('not found')
  end
end
