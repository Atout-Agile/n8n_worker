# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: assistantEvents', type: :request do
  let(:role) { create(:role, :user) }
  let!(:read_perm) { create(:permission, name: 'assistant_config:read') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << read_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      query Events($from: ISO8601DateTime!, $to: ISO8601DateTime!) {
        assistantEvents(from: $from, to: $to) { id title }
      }
    GQL
  end

  it "lists user's events within a window" do
    t = Time.utc(2026, 6, 10, 14)
    kept = create(:calendar_event, user: user, starts_at: t, ends_at: t + 1.hour)
    t2 = Time.utc(2027, 1, 1, 10)
    create(:calendar_event, user: user, starts_at: t2, ends_at: t2 + 1.hour)
    variables = { from: '2026-01-01T00:00:00Z', to: '2026-12-31T23:59:59Z' }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    ids = json['data']['assistantEvents'].map { |e| e['id'] }
    expect(ids).to include(kept.id.to_s)
  end

  it 'excludes events from other users' do
    other = create(:user, role: role)
    t = Time.utc(2026, 6, 10, 14)
    create(:calendar_event, user: other, starts_at: t, ends_at: t + 1.hour)
    variables = { from: '2026-01-01T00:00:00Z', to: '2026-12-31T23:59:59Z' }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['assistantEvents']).to eq []
  end
end
