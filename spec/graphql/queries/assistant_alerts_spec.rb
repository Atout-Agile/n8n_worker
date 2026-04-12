# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: assistantAlerts', type: :request do
  let(:role) { create(:role, :user) }
  let!(:read_perm) { create(:permission, name: 'assistant_alerts:read') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << read_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      query Alerts($limit: Int) {
        assistantAlerts(limit: $limit) { id emittedAt contentSnapshot }
      }
    GQL
  end

  it "returns only the current user's alerts, newest first" do
    older = create(:alert_emission, user: user, emitted_at: 2.hours.ago)
    newer = create(:alert_emission, user: user, emitted_at: 1.hour.ago)
    create(:alert_emission, user: create(:user, role: role))
    post '/graphql', params: { query: query, variables: { limit: 10 } }.to_json, headers: headers
    json = JSON.parse(response.body)
    ids = json['data']['assistantAlerts'].map { |a| a['id'] }
    expect(ids).to eq [ newer.id.to_s, older.id.to_s ]
  end
end
