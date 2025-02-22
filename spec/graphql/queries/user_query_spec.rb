# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Queries::User", type: :request do
  let(:role) { create(:role, :user) }
  let!(:user) { create(:user, role: role) }

  let(:query_by_id) do
    <<~GQL
      query($id: ID!) {
        user(id: $id) {
          id
          email
          username
          role {
            name
          }
        }
      }
    GQL
  end

  let(:query_by_email) do
    <<~GQL
      query($email: String!) {
        user(email: $email) {
          id
          email
          username
          role {
            name
          }
        }
      }
    GQL
  end

  describe 'user query' do
    context 'when querying by ID' do
      it 'returns the user when found' do
        post '/graphql', params: { 
          query: query_by_id,
          variables: { id: user.id.to_s }
        }

        json = JSON.parse(response.body)
        data = json['data']['user']

        expect(data).to include(
          'id' => user.id.to_s,
          'email' => user.email,
          'username' => user.name,
          'role' => { 'name' => role.name }
        )
      end

      it 'returns null when user is not found' do
        post '/graphql', params: { 
          query: query_by_id,
          variables: { id: (User.last.id + 1).to_s }
        }

        json = JSON.parse(response.body)
        expect(json['data']['user']).to be_nil
      end
    end

    context 'when querying by email' do
      it 'returns the user when found' do
        post '/graphql', params: { 
          query: query_by_email,
          variables: { email: user.email }
        }

        json = JSON.parse(response.body)
        data = json['data']['user']

        expect(data).to include(
          'id' => user.id.to_s,
          'email' => user.email,
          'username' => user.name,
          'role' => { 'name' => role.name }
        )
      end

      it 'returns null when user is not found' do
        post '/graphql', params: { 
          query: query_by_email,
          variables: { email: "nonexistent@example.com" }
        }

        json = JSON.parse(response.body)
        expect(json['data']['user']).to be_nil
      end
    end
  end
end 