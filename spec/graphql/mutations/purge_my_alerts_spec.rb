# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: purgeMyAlerts', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_alerts:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation Purge($before: ISO8601DateTime, $ids: [ID!]) {
        purgeMyAlerts(before: $before, ids: $ids) { purgedCount errors }
      }
    GQL
  end

  it 'purges everything older than `before`' do
    create(:alert_emission, user: user, emitted_at: 3.hours.ago)
    create(:alert_emission, user: user, emitted_at: 30.minutes.ago)
    variables = { before: 1.hour.ago.iso8601 }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['purgeMyAlerts']['purgedCount']).to eq 1
    expect(user.alert_emissions.count).to eq 1
  end

  it 'purges specific ids' do
    a = create(:alert_emission, user: user)
    b = create(:alert_emission, user: user)
    variables = { ids: [ a.id.to_s ] }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    expect(AlertEmission.exists?(a.id)).to be false
    expect(AlertEmission.exists?(b.id)).to be true
  end

  it "never purges another user's alerts" do
    other = create(:user, role: role)
    their_alert = create(:alert_emission, user: other)
    variables = { ids: [ their_alert.id.to_s ] }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    expect(AlertEmission.exists?(their_alert.id)).to be true
  end
end
