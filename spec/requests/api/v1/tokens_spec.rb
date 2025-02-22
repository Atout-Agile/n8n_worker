# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::Tokens", type: :request do
  describe "GET /create" do
    let(:role) { create(:role) }
    let(:user) { create(:user, role: role) }
    let(:token) { create(:api_token, user: user) }

    it "returns http success" do
      get "/api/v1/tokens/create", params: { id: token.id }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(token.name)
    end
  end

end
