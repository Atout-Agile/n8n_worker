# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: setCalendarSource mutation', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation SetSource($url: String!) {
        setCalendarSource(url: $url) {
          assistantConfig { calendarSourceUrl calendarSourceType }
          errors
        }
      }
    GQL
  end

  it 'stores the ICS URL on the user config' do
    post '/graphql',
         params: { query: query, variables: { url: 'https://calendar.example.com/feed.ics' } }.to_json,
         headers: headers
    json = JSON.parse(response.body)
    data = json['data']['setCalendarSource']
    expect(data['errors']).to eq []
    expect(data['assistantConfig']['calendarSourceUrl']).to eq 'https://calendar.example.com/feed.ics'
    expect(data['assistantConfig']['calendarSourceType']).to eq 'ics'
  end
end
