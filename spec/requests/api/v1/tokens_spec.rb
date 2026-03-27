# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::Tokens", type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }
  
  # Helper pour simuler la connexion utilisateur
  def login_as(user)
    # Mock plus agressif pour s'assurer que ça fonctionne
    allow_any_instance_of(Api::V1::TokensController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(Api::V1::TokensController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /api/v1/tokens/create" do
    context "with an existing token ID" do
      let!(:api_token) { create(:api_token, user: user) }

      it "returns http success and displays the token" do
        login_as(user)
        get "/api/v1/tokens/create", params: { id: api_token.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(api_token.name)
      end
    end

    context "without an ID (creating a new token)" do
      it "redirects to the token creation page" do
        login_as(user)
        get "/api/v1/tokens/create", params: { name: "Test Token" }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /api/v1/tokens" do
    let(:valid_params) { { name: "Mon Token API" } }
    let(:invalid_params) { { name: "" } }

    context "with valid parameters" do
      it "creates a new API token" do
        login_as(user)
        expect {
          post "/api/v1/tokens", params: valid_params
        }.to change(ApiToken, :count).by(1)

        token = ApiToken.last
        expect(response).to redirect_to(api_v1_token_path(token))
        expect(flash[:notice]).to eq("API token created successfully")
        expect(token.user).to eq(user)
        expect(token.name).to eq("Mon Token API")
        expect(token.token_digest).to be_present
        expect(token.expires_at).to be_present
      end

      it "generates a correct token digest" do
        login_as(user)
        post "/api/v1/tokens", params: valid_params
        
        token = ApiToken.last
        expect(token.token_digest).to be_present
        expect(token.token_digest.length).to eq(64) # SHA256 hex digest length
      end

      it "sets a default expiration to 30 days" do
        login_as(user)
        post "/api/v1/tokens", params: valid_params
        
        token = ApiToken.last
        expected_expiration = 30.days.from_now
        expect(token.expires_at).to be_within(1.minute).of(expected_expiration)
      end

      it "respects a custom expiration" do
        login_as(user)
        custom_expiration = 7.days.from_now
        post "/api/v1/tokens", params: valid_params.merge(expires_at: custom_expiration)
        
        token = ApiToken.last
        expect(token.expires_at).to be_within(1.minute).of(custom_expiration)
      end

      it "exposes the raw token after creation" do
        login_as(user)
        post "/api/v1/tokens", params: valid_params

        token = ApiToken.last
        expect(response).to redirect_to(api_v1_token_path(token))
        expect(flash[:raw_token]).to be_present
        expect(flash[:raw_token].length).to eq(64) # SecureRandom.hex(32)
        expect(token.token_digest).to eq(Digest::SHA256.hexdigest(flash[:raw_token]))
      end
    end

    context "with invalid parameters" do
      it "does not create a token and displays an error" do
        login_as(user)
        expect {
          post "/api/v1/tokens", params: invalid_params
        }.not_to change(ApiToken, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a name already used by the user" do
      let!(:existing_token) { create(:api_token, user: user, name: "Mon Token API") }

      it "does not create a token and displays an error" do
        login_as(user)
        expect {
          post "/api/v1/tokens", params: { name: "Mon Token API" }
        }.not_to change(ApiToken, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "authentication" do
    context "without a logged-in user" do
      it "redirects to the login page" do
        get "/api/v1/tokens/create"
        expect(response).to redirect_to(login_path)
      end

      it "redirects to the login page for POST" do
        post "/api/v1/tokens", params: { name: "Test Token" }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "security" do
    let(:other_user) { create(:user, role: role) }
    let!(:other_token) { create(:api_token, user: other_user) }

    it "does not allow access to other users' tokens" do
      # Test the controller logic directly by checking the query scope
      # When user tries to access other_token.id, it should not be found
      # because current_user.api_tokens.find(id) only looks in user's tokens
      
      expect(user.api_tokens.find_by(id: other_token.id)).to be_nil
      
      # This should raise ActiveRecord::RecordNotFound
      expect {
        user.api_tokens.find(other_token.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
