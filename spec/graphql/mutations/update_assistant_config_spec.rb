# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: updateAssistantConfig mutation', type: :request do
  let(:role) { create(:role, :user) }
  let!(:write_perm) { create(:permission, name: 'assistant_config:write') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << write_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      mutation UpdateAssistantConfig($timezone: String, $reminderIntervals: [Int!]) {
        updateAssistantConfig(timezone: $timezone, reminderIntervals: $reminderIntervals) {
          assistantConfig { timezone reminderIntervals }
          errors
        }
      }
    GQL
  end

  it 'updates the timezone and reminder intervals' do
    variables = { timezone: 'Europe/Paris', reminderIntervals: [ 60, 15, 5 ] }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['updateAssistantConfig']
    expect(data['errors']).to eq []
    expect(data['assistantConfig']['timezone']).to eq 'Europe/Paris'
    expect(data['assistantConfig']['reminderIntervals']).to eq [ 60, 15, 5 ]
  end

  it 'accepts an empty reminder_intervals list' do
    variables = { reminderIntervals: [] }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    data = json['data']['updateAssistantConfig']
    expect(data['errors']).to eq []
    expect(data['assistantConfig']['reminderIntervals']).to eq []
  end

  it 'returns errors for an invalid timezone' do
    variables = { timezone: 'Nowhere/Imaginary' }
    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['updateAssistantConfig']['errors'].join).to match(/timezone/i)
  end
end
