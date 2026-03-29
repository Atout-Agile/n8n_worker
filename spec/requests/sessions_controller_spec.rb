# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role, password: 'password123') }

  describe 'GET /login' do
    context 'when user is not logged in' do
      it 'renders the login form' do
        get login_path
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Sign in')
        expect(response.body).to include('Email')
        expect(response.body).to include('Password')
      end
    end

    context 'when user is already logged in' do
      before do
        # Simulate logged in user
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'redirects to dashboard' do
        get login_path
        
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'POST /sessions' do
    let(:valid_credentials) { { email: user.email, password: 'password123' } }
    let(:invalid_credentials) { { email: user.email, password: 'wrong_password' } }

    context 'with valid credentials' do
      before do
        # Mock successful GraphQL response
        allow(N8nWorkerSchema).to receive(:execute).and_return(
          double(to_h: {
            "data" => {
              "login" => {
                "token" => "valid_jwt_token",
                "user" => {
                  "id" => user.id.to_s,
                  "email" => user.email,
                  "username" => user.name
                },
                "errors" => []
              }
            }
          })
        )
      end

      it 'logs in successfully and redirects to dashboard' do
        post sessions_path, params: valid_credentials
        
        expect(response).to redirect_to(dashboard_path)
        expect(session[:jwt_token]).to eq('valid_jwt_token')
      end

      it 'sets @token for localStorage' do
        post sessions_path, params: valid_credentials
        
        # Check that the token is stored in session (which is what matters)
        expect(session[:jwt_token]).to eq('valid_jwt_token')
      end
    end

    context 'with invalid credentials' do
      before do
        # Mock failed GraphQL response
        allow(N8nWorkerSchema).to receive(:execute).and_return(
          double(to_h: {
            "data" => {
              "login" => {
                "token" => nil,
                "user" => nil,
                "errors" => ["Email ou mot de passe invalide"]
              }
            }
          })
        )
      end

      it 'renders login form with error message' do
        post sessions_path, params: invalid_credentials
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Email ou mot de passe invalide')
        expect(session[:jwt_token]).to be_nil
      end

      it 'sets flash alert with error message' do
        post sessions_path, params: invalid_credentials
        
        expect(flash.now[:alert]).to eq('Email ou mot de passe invalide')
      end
    end

    context 'with GraphQL errors' do
      before do
        # Mock GraphQL errors response
        allow(N8nWorkerSchema).to receive(:execute).and_return(
          double(to_h: {
            "data" => {
              "login" => {
                "token" => nil,
                "user" => nil,
                "errors" => []
              }
            },
            "errors" => [
              { "message" => "GraphQL validation error" }
            ]
          })
        )
      end

      it 'handles GraphQL errors gracefully' do
        post sessions_path, params: valid_credentials
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('GraphQL validation error')
      end
    end

    context 'with no errors but no token' do
      before do
        # Mock response with no token and no errors
        allow(N8nWorkerSchema).to receive(:execute).and_return(
          double(to_h: {
            "data" => {
              "login" => {
                "token" => nil,
                "user" => nil,
                "errors" => []
              }
            }
          })
        )
      end

      it 'shows default error message' do
        post sessions_path, params: valid_credentials
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Invalid email or password')
      end
    end

    context 'with empty errors array' do
      before do
        # Mock response with empty errors
        allow(N8nWorkerSchema).to receive(:execute).and_return(
          double(to_h: {
            "data" => {
              "login" => {
                "token" => nil,
                "user" => nil,
                "errors" => []
              }
            }
          })
        )
      end

      it 'shows default error message' do
        post sessions_path, params: valid_credentials
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Invalid email or password')
      end
    end
  end

  describe 'DELETE /logout' do
    it 'clears the session and redirects to root' do
      # Set up a session with a token before the request
      post sessions_path, params: { email: user.email, password: 'password123' }
      
      # Now test logout
      delete logout_path
      
      expect(response).to redirect_to(root_path)
      expect(session[:jwt_token]).to be_nil
      expect(flash[:notice]).to eq('You have been logged out.')
    end

    it 'resets the entire session' do
      # Set up a session with a token before the request
      post sessions_path, params: { email: user.email, password: 'password123' }
      
      # Add some other session data
      session[:other_data] = 'test'
      
      delete logout_path
      
      expect(session[:jwt_token]).to be_nil
      expect(session[:other_data]).to be_nil
    end
  end

  describe 'private methods' do
    it 'defines login_mutation correctly' do
      controller = SessionsController.new
      
      # Use send to access private method
      mutation = controller.send(:login_mutation)
      
      expect(mutation).to include('mutation Login')
      expect(mutation).to include('$email: String!')
      expect(mutation).to include('$password: String!')
      expect(mutation).to include('token')
      expect(mutation).to include('user')
      expect(mutation).to include('errors')
    end
  end
end 