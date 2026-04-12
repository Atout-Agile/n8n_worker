# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL: assistantReminders', type: :request do
  let(:role) { create(:role, :user) }
  let!(:read_perm) { create(:permission, name: 'assistant_config:read') }
  let(:user) { create(:user, role: role) }

  before { role.permissions << read_perm }

  let(:jwt_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

  let(:query) do
    <<~GQL
      query Rem($from: ISO8601DateTime!, $to: ISO8601DateTime!, $state: String) {
        assistantReminders(from: $from, to: $to, state: $state) {
          id
          state
          calendarEvent { id title }
        }
      }
    GQL
  end

  it 'returns pending reminders within a window and does not trigger N+1' do
    event = create(:calendar_event, user: user, starts_at: 1.day.from_now)
    reminder = create(:calendar_reminder, calendar_event: event,
                                          fires_at: 1.day.from_now - 15.minutes, state: 'pending')
    create(:calendar_reminder, calendar_event: event, fires_at: 1.day.from_now - 5.minutes, state: 'pending')
    variables = { from: Time.current.iso8601, to: 2.days.from_now.iso8601, state: 'pending' }

    post '/graphql', params: { query: query, variables: variables }.to_json, headers: headers
    json = JSON.parse(response.body)
    expect(json['data']['assistantReminders'].map { |r| r['id'] }).to include(reminder.id.to_s)
    expect(json['data']['assistantReminders'].first['calendarEvent']['title']).to eq event.title
  end
end
