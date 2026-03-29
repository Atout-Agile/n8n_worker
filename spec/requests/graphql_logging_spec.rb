# frozen_string_literal: true

require 'rails_helper'

# Verifies structured logging behaviour for GraphQL requests:
#   - last_used_at is updated on API token auth
#   - authorized token requests emit a graphql.token_access log entry
#   - denied requests emit a graphql.access_denied log entry
RSpec.describe "GraphQL logging", type: :request do
  let!(:tokens_read_perm) { create(:permission, :tokens_read) }
  let!(:users_read_perm)  { create(:permission, :users_read) }

  let(:role) { create(:role).tap { |r| r.permissions << tokens_read_perm } }
  let(:user) { create(:user, role: role) }

  let(:raw_token) { SecureRandom.hex(32) }
  let!(:api_token) do
    create(:api_token,
      user: user,
      token_digest: Digest::SHA256.hexdigest(raw_token),
      permissions: [tokens_read_perm])
  end

  let(:valid_query)  { "query GetTokens { apiTokens { id name } }" }
  let(:denied_query) { "query GetUsers { users { id } }" }

  def post_graphql(query, token: nil, operation: nil)
    headers = token ? { "Authorization" => "Bearer #{token}" } : {}
    post "/graphql",
      params: { query: query, operationName: operation }.compact,
      headers: headers
  end

  # Helper: intercept a specific log level and return the first message
  # matching the given substring.
  def capture_log(level, substring)
    logged = nil
    allow(Rails.logger).to receive(level) do |msg|
      logged = msg if msg.to_s.include?(substring)
    end
    yield
    logged
  end

  # ─────────────────────────────────────────
  # last_used_at
  # ─────────────────────────────────────────
  describe "last_used_at update" do
    it "updates last_used_at after a successful API token request" do
      expect {
        post_graphql(valid_query, token: raw_token)
      }.to change { api_token.reload.last_used_at }
    end

    it "does not update last_used_at when using JWT authentication" do
      jwt = JsonWebToken.encode(user_id: user.id)
      # Ensure last_used_at starts as nil (never used)
      expect(api_token.last_used_at).to be_nil
      post_graphql(valid_query, token: jwt)
      expect(api_token.reload.last_used_at).to be_nil
    end
  end

  # ─────────────────────────────────────────
  # Authorized access log
  # ─────────────────────────────────────────
  describe "graphql.token_access log" do
    it "logs an info entry with token_id, user_id, and operation" do
      logged = capture_log(:info, "graphql.token_access") do
        post_graphql(valid_query, token: raw_token, operation: "GetTokens")  # named op
      end

      expect(logged).to be_present
      payload = JSON.parse(logged)
      expect(payload["event"]).to eq("graphql.token_access")
      expect(payload["token_id"]).to eq(api_token.id)
      expect(payload["user_id"]).to eq(user.id)
      expect(payload["operation"]).to eq("GetTokens")
    end

    it "does not emit graphql.token_access for JWT requests" do
      jwt = JsonWebToken.encode(user_id: user.id)
      logged = capture_log(:info, "graphql.token_access") do
        post_graphql(valid_query, token: jwt, operation: "GetTokens")
      end
      expect(logged).to be_nil
    end
  end

  # ─────────────────────────────────────────
  # Denied access log
  # ─────────────────────────────────────────
  describe "graphql.access_denied log" do
    it "logs a warn entry with user_id, token_id, operation, and rule when access is denied" do
      # api_token only has tokens:read; users query requires users:read
      logged = capture_log(:warn, "graphql.access_denied") do
        post_graphql(denied_query, token: raw_token, operation: "GetUsers")  # named op
      end

      expect(logged).to be_present
      payload = JSON.parse(logged)
      expect(payload["event"]).to eq("graphql.access_denied")
      expect(payload["user_id"]).to eq(user.id)
      expect(payload["token_id"]).to eq(api_token.id)
      expect(payload["operation"]).to eq("GetUsers")
      expect(payload["rule"]).to be_present
    end

    it "logs access_denied with nil user_id and token_id when unauthenticated" do
      logged = capture_log(:warn, "graphql.access_denied") do
        post_graphql(denied_query, operation: "GetUsers")
      end

      expect(logged).to be_present
      payload = JSON.parse(logged)
      expect(payload["event"]).to eq("graphql.access_denied")
      expect(payload["user_id"]).to be_nil
      expect(payload["token_id"]).to be_nil
    end
  end
end
