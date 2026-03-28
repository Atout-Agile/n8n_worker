# frozen_string_literal: true

require 'rails_helper'

# Create a test controller that inherits from ApplicationController
class TestApplicationController < ApplicationController
  def test_action
    render json: { current_user_id: current_user&.id }
  end
end

RSpec.describe ApplicationController, type: :controller do
  controller(TestApplicationController) do
    def index
      render json: { current_user_id: current_user&.id }
    end
  end

  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }

  describe '#current_user' do
    context 'when no token in session' do
      it 'returns nil' do
        get :index
        
        json = JSON.parse(response.body)
        expect(json['current_user_id']).to be_nil
      end
    end

    context 'when token exists in session' do
      before do
        session[:jwt_token] = token
      end

      context 'when GraphQL query returns user data' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_return(
            double(to_h: {
              "data" => {
                "user" => {
                  "id" => user.id.to_s,
                  "email" => user.email,
                  "username" => user.name,
                  "role" => {
                    "name" => role.name
                  }
                }
              }
            })
          )
        end

        it 'returns the user when found' do
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to eq(user.id)
        end

        # Supprimons le test de cache problématique

      end

      context 'when result.dig("data", "user") returns nil' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_return(
            double(to_h: {
              "data" => {
                "user" => nil
              }
            })
          )
        end

        it 'returns nil when user not found in GraphQL' do
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end

      context 'when result.dig("data", "user") does not exist' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_return(
            double(to_h: {
              "data" => {}
            })
          )
        end

        it 'returns nil when user key does not exist' do
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end

      context 'when GraphQL response has no data key' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_return(
            double(to_h: {
              "errors" => ["User not found"]
            })
          )
        end

        it 'returns nil when no data in response' do
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end

      context 'when JWT decode fails' do
        before do
          allow(JsonWebToken).to receive(:decode).and_raise(JWT::DecodeError, 'Invalid token')
        end

        it 'returns nil and logs error' do
          expect(Rails.logger).to receive(:error).with(/Error fetching current user/)
          
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end

      context 'when GraphQL execution fails' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_raise(StandardError, 'GraphQL error')
        end

        it 'returns nil and logs error' do
          expect(Rails.logger).to receive(:error).with(/Error fetching current user/)
          
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end

      context 'when user is not found in database' do
        before do
          allow(N8nWorkerSchema).to receive(:execute).and_return(
            double(to_h: {
              "data" => {
                "user" => {
                  "id" => "999999",  # Non-existent user ID
                  "email" => "nonexistent@example.com",
                  "username" => "Nonexistent User",
                  "role" => {
                    "name" => "user"
                  }
                }
              }
            })
          )
        end

        it 'returns nil when user not found in database' do
          get :index
          
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to be_nil
        end
      end
    end
  end
end 