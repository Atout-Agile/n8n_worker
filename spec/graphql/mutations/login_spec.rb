# frozen_string_literal: true
require 'rails_helper'


RSpec.describe Mutations::Login, type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role, password: 'password123') }
  let(:query) do
    <<~GQL
      mutation Login($email: String!, $password: String!) {
        login(input: { email: $email, password: $password }) {
          token
          user {
            id
            email
            username
          }
          errors
        }
      }
    GQL
  end

  describe 'login mutation' do
    context 'with valid credentials' do
      let(:variables) { { email: user.email, password: 'password123' } }

      it 'returns token and user info' do
        post '/graphql', params: { query: query, variables: variables }
        
        json = JSON.parse(response.body)
        data = json['data']['login']
        
        expect(data['token']).to be_present
        expect(data['user']['email']).to eq(user.email)
        expect(data['user']['username']).to eq(user.name)
        expect(data['errors']).to be_empty
      end
    end

    context 'with invalid credentials' do
      let(:variables) { { email: user.email, password: 'wrong_password' } }

      it 'returns error message' do
        post '/graphql', params: { query: query, variables: variables }
        
        json = JSON.parse(response.body)
        data = json['data']['login']
        
        expect(data['token']).to be_nil
        expect(data['user']).to be_nil
        expect(data['errors']).to include('Email ou mot de passe invalide')
      end
    end

    context 'with non-existent user' do
      let(:variables) { { email: 'nonexistent@example.com', password: 'password123' } }

      it 'returns error message' do
        post '/graphql', params: { query: query, variables: variables }
        
        json = JSON.parse(response.body)
        data = json['data']['login']
        
        expect(data['token']).to be_nil
        expect(data['user']).to be_nil
        expect(data['errors']).to include('Email ou mot de passe invalide')
      end
    end
  end
end
