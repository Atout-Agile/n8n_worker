# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::Tokens", type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }
  
  # Authenticates via the real session flow so current_user runs with its includes.
  def login_as(user)
    post sessions_path, params: { email: user.email, password: 'password123' }
  end

  describe "GET /api/v1/tokens" do
    context "with existing tokens" do
      let!(:api_token) { create(:api_token, user: user) }

      it "returns http success and lists tokens" do
        login_as(user)
        get "/api/v1/tokens"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(api_token.name)
      end
    end

    context "with no tokens" do
      it "redirects to the new token form" do
        login_as(user)
        get "/api/v1/tokens"
        expect(response).to redirect_to(new_api_v1_token_path)
      end
    end
  end

  describe "GET /api/v1/tokens/new" do
    it "returns http success and displays the form" do
      login_as(user)
      get "/api/v1/tokens/new"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Create token")
    end

    context "with role permissions" do
      let!(:perm) { create(:permission, :users_read) }

      before { role.permissions << perm }

      it "displays only the role's non-deprecated permissions" do
        login_as(user)
        get "/api/v1/tokens/new"
        expect(response.body).to include(perm.name)
      end

      it "does not display permissions from other roles" do
        other_perm = create(:permission, :tokens_write)
        login_as(user)
        get "/api/v1/tokens/new"
        expect(response.body).not_to include(other_perm.name)
      end

      it "does not display deprecated permissions" do
        deprecated = create(:permission, name: "old:read", description: "Old", deprecated: true)
        role.permissions << deprecated
        login_as(user)
        get "/api/v1/tokens/new"
        expect(response.body).not_to include("old:read")
      end
    end

    context "with no role permissions" do
      it "shows a message that the role has no permissions" do
        login_as(user)
        get "/api/v1/tokens/new"
        expect(response.body).to include("Your role has no permissions assigned")
      end
    end
  end

  describe "GET /api/v1/tokens/:id" do
    let!(:api_token) { create(:api_token, user: user) }

    it "returns http success and displays the token" do
      login_as(user)
      get "/api/v1/tokens/#{api_token.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(api_token.name)
    end

    context "with assigned permissions" do
      let!(:perm) { create(:permission, :users_read) }

      before do
        role.permissions << perm
        api_token.permissions << perm
      end

      it "displays the token permissions" do
        login_as(user)
        get "/api/v1/tokens/#{api_token.id}"
        expect(response.body).to include(perm.name)
      end
    end

    context "with no assigned permissions" do
      it "shows that no permissions are assigned" do
        login_as(user)
        get "/api/v1/tokens/#{api_token.id}"
        expect(response.body).to include("No permissions assigned")
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

    context "with valid permissions (subset of role)" do
      let!(:perm_read)  { create(:permission, :users_read) }
      let!(:perm_write) { create(:permission, :users_write) }

      before { role.permissions << [perm_read, perm_write] }

      it "creates a token with the selected permissions" do
        login_as(user)
        post "/api/v1/tokens", params: {
          name: "Scoped Token",
          token: { permission_ids: [perm_read.id] }
        }
        token = ApiToken.last
        expect(token.permissions).to contain_exactly(perm_read)
      end

      it "creates a token with no permissions when none are selected" do
        login_as(user)
        post "/api/v1/tokens", params: { name: "Empty Token" }
        expect(ApiToken.last.permissions).to be_empty
      end
    end

    context "with a permission outside the user's role" do
      let!(:other_perm) { create(:permission, :tokens_write) }

      it "silently ignores the out-of-scope permission and creates the token without it" do
        login_as(user)
        post "/api/v1/tokens", params: {
          name: "Injection Attempt",
          token: { permission_ids: [other_perm.id] }
        }
        expect(response).to redirect_to(api_v1_token_path(ApiToken.last))
        expect(ApiToken.last.permissions).to be_empty
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

  describe "PATCH /api/v1/tokens/:id/revoke" do
    let!(:api_token) { create(:api_token, user: user) }

    it "sets expires_at to now, making the token inactive" do
      login_as(user)
      expect(api_token.active?).to be true
      patch "/api/v1/tokens/#{api_token.id}/revoke"
      expect(response).to redirect_to(api_v1_tokens_path)
      expect(flash[:notice]).to include("has been revoked")
      expect(api_token.reload.active?).to be false
    end

    it "does not affect tokens belonging to another user" do
      other_user = create(:user, role: role)
      other_token = create(:api_token, user: other_user)
      login_as(user)
      patch "/api/v1/tokens/#{other_token.id}/revoke"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/tokens/:id/renew" do
    let!(:api_token) { create(:api_token, user: user, expires_at: 1.day.from_now) }

    it "extends expiration by 30 days from now" do
      login_as(user)
      patch "/api/v1/tokens/#{api_token.id}/renew"
      expect(response).to redirect_to(api_v1_tokens_path)
      expect(flash[:notice]).to include("renewed")
      expect(api_token.reload.expires_at).to be_within(1.minute).of(30.days.from_now)
    end

    it "renews an already expired token" do
      api_token.update!(expires_at: 1.day.ago)
      login_as(user)
      patch "/api/v1/tokens/#{api_token.id}/renew"
      expect(api_token.reload.active?).to be true
    end
  end

  describe "DELETE /api/v1/tokens/:id" do
    let!(:api_token) { create(:api_token, user: user) }

    it "deletes the token" do
      login_as(user)
      expect {
        delete "/api/v1/tokens/#{api_token.id}"
      }.to change(ApiToken, :count).by(-1)
      expect(response).to redirect_to(api_v1_tokens_path)
      expect(flash[:notice]).to include("has been deleted")
    end

    it "does not allow deleting another user's token" do
      other_user = create(:user, role: role)
      other_token = create(:api_token, user: other_user)
      login_as(user)
      expect {
        delete "/api/v1/tokens/#{other_token.id}"
      }.not_to change(ApiToken, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "authentication" do
    context "without a logged-in user" do
      it "redirects to the login page for GET index" do
        get "/api/v1/tokens"
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
