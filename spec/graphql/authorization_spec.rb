# frozen_string_literal: true

require 'rails_helper'

# Comprehensive authorization spec for Story 3 — Action Policy integration.
# Verifies that each GraphQL operation enforces the correct permission,
# and that both auth modes (JWT and API token) resolve permissions correctly.
RSpec.describe "GraphQL Authorization" do
  # Permissions
  let!(:users_read)   { create(:permission, :users_read) }
  let!(:users_write)  { create(:permission, :users_write) }
  let!(:tokens_read)  { create(:permission, :tokens_read) }
  let!(:tokens_write) { create(:permission, :tokens_write) }

  # A role with ALL permissions
  let(:full_role) do
    r = create(:role)
    r.permissions = [users_read, users_write, tokens_read, tokens_write]
    r
  end

  # A role with NO permissions
  let(:empty_role) { create(:role) }

  let(:full_user)  { create(:user, role: full_role) }
  let(:empty_user) { create(:user, role: empty_role) }

  # Helper: run a query with a direct schema execute context
  def gql(query_str, variables: {}, user: nil, token: nil)
    N8nWorkerSchema.execute(
      query_str,
      variables: variables,
      context: { current_user: user, current_token: token }
    ).to_h
  end

  def not_authorized?(result)
    result.dig("errors", 0, "message") == "NOT_AUTHORIZED" &&
      result.dig("errors", 0, "extensions", "code") == "UNAUTHORIZED"
  end

  # ────────────────────────────────────────────
  # Login mutation — public, no permission needed
  # ────────────────────────────────────────────
  describe "login mutation (public)" do
    let(:mutation) do
      <<~GQL
        mutation Login($email: String!, $password: String!) {
          login(email: $email, password: $password) {
            token
            errors
          }
        }
      GQL
    end

    it "succeeds without any permissions" do
      result = gql(mutation, variables: { email: empty_user.email, password: "password123" })
      expect(result.dig("data", "login", "token")).to be_present
      expect(not_authorized?(result)).to be false
    end
  end

  # ────────────────────────────────────────────
  # Query: user  (requires users:read)
  # ────────────────────────────────────────────
  describe "user query (requires users:read)" do
    let(:query) do
      <<~GQL
        query { user(id: "#{full_user.id}") { id email } }
      GQL
    end

    it "succeeds with users:read" do
      result = gql(query, user: full_user)
      expect(result.dig("data", "user", "id")).to eq(full_user.id.to_s)
    end

    it "returns NOT_AUTHORIZED without users:read" do
      result = gql(query, user: empty_user)
      expect(not_authorized?(result)).to be true
    end

    it "returns NOT_AUTHORIZED when unauthenticated" do
      result = gql(query)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Query: users  (requires users:read)
  # ────────────────────────────────────────────
  describe "users query (requires users:read)" do
    let(:query) { "query { users { id } }" }

    it "succeeds with users:read" do
      result = gql(query, user: full_user)
      expect(result.dig("data", "users")).to be_an(Array)
    end

    it "returns NOT_AUTHORIZED without users:read" do
      result = gql(query, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Mutation: updateUser  (requires users:write)
  # ────────────────────────────────────────────
  describe "updateUser mutation (requires users:write)" do
    let(:mutation) do
      <<~GQL
        mutation UpdateUser($id: ID!, $name: String) {
          updateUser(id: $id, name: $name) {
            user { id }
            errors
          }
        }
      GQL
    end

    it "succeeds with users:write" do
      result = gql(mutation, variables: { id: full_user.id.to_s, name: "New Name" }, user: full_user)
      expect(result.dig("data", "updateUser", "errors")).to be_empty
    end

    it "returns NOT_AUTHORIZED without users:write" do
      result = gql(mutation, variables: { id: empty_user.id.to_s, name: "New Name" }, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Query: apiTokens  (requires tokens:read)
  # ────────────────────────────────────────────
  describe "apiTokens query (requires tokens:read)" do
    let(:query) { "query { apiTokens { id name } }" }

    it "succeeds with tokens:read" do
      result = gql(query, user: full_user)
      expect(result.dig("data", "apiTokens")).to be_an(Array)
    end

    it "returns NOT_AUTHORIZED without tokens:read" do
      result = gql(query, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Query: verifyToken  (requires tokens:read)
  # ────────────────────────────────────────────
  describe "verifyToken query (requires tokens:read)" do
    let(:raw)   { SecureRandom.hex(32) }
    let!(:tok)  { create(:api_token, user: full_user, token_digest: Digest::SHA256.hexdigest(raw)) }
    let(:query) { "query { verifyToken(token: \"#{raw}\") { id } }" }

    it "succeeds with tokens:read" do
      result = gql(query, user: full_user)
      expect(result.dig("data", "verifyToken", "id")).to eq(tok.id.to_s)
    end

    it "returns NOT_AUTHORIZED without tokens:read" do
      result = gql(query, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Mutation: createApiToken  (requires tokens:write)
  # ────────────────────────────────────────────
  describe "createApiToken mutation (requires tokens:write)" do
    let(:mutation) do
      <<~GQL
        mutation {
          createApiToken(name: "Test Token") {
            apiToken { id }
            errors
          }
        }
      GQL
    end

    it "succeeds with tokens:write" do
      result = gql(mutation, user: full_user)
      expect(result.dig("data", "createApiToken", "apiToken")).to be_present
    end

    it "returns NOT_AUTHORIZED without tokens:write" do
      result = gql(mutation, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Mutation: revokeApiToken  (requires tokens:write)
  # ────────────────────────────────────────────
  describe "revokeApiToken mutation (requires tokens:write)" do
    let!(:api_token) { create(:api_token, user: full_user) }
    let(:mutation) do
      <<~GQL
        mutation { revokeApiToken(id: "#{api_token.id}") { success errors } }
      GQL
    end

    it "succeeds with tokens:write" do
      result = gql(mutation, user: full_user)
      expect(result.dig("data", "revokeApiToken", "success")).to be true
    end

    it "returns NOT_AUTHORIZED without tokens:write" do
      result = gql(mutation, user: empty_user)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # JWT auth → uses role permissions
  # ────────────────────────────────────────────
  describe "JWT auth mode uses role permissions" do
    it "grants access when the role has the permission" do
      role = create(:role)
      role.permissions << users_read
      user = create(:user, role: role)

      query = "query { user(id: \"#{user.id}\") { id } }"
      # JWT auth: context[:current_token] is nil
      result = gql(query, user: user, token: nil)
      expect(result.dig("data", "user", "id")).to eq(user.id.to_s)
    end

    it "denies access when the role lacks the permission" do
      query = "query { user(id: \"#{empty_user.id}\") { id } }"
      result = gql(query, user: empty_user, token: nil)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # API token auth → uses token permissions (not role)
  # ────────────────────────────────────────────
  describe "API token auth mode uses token permissions" do
    it "grants access when the API token has the permission" do
      # role has tokens:read; token is scoped to exactly that permission
      role = create(:role)
      role.permissions << tokens_read
      user = create(:user, role: role)
      token_record = create(:api_token, user: user, permissions: [tokens_read])

      result = gql("query { apiTokens { id } }", user: user, token: token_record)
      expect(result.dig("data", "apiTokens")).to be_an(Array)
    end

    it "denies access when the API token lacks the permission (even if role would allow it)" do
      # full_user role has all permissions, but the token holds only users:read
      token_record = create(:api_token, user: full_user, permissions: [users_read])

      result = gql("query { apiTokens { id } }", user: full_user, token: token_record)
      expect(not_authorized?(result)).to be true
    end
  end

  # ────────────────────────────────────────────
  # Token with no permissions
  # ────────────────────────────────────────────
  describe "token with no permissions" do
    let(:token_record) { create(:api_token, user: full_user, permissions: []) }

    [
      "query { users { id } }",
      "query { apiTokens { id } }"
    ].each do |protected_query|
      it "denies #{protected_query.inspect}" do
        result = gql(protected_query, user: full_user, token: token_record)
        expect(not_authorized?(result)).to be true
      end
    end
  end

  # ────────────────────────────────────────────
  # Error format
  # ────────────────────────────────────────────
  describe "NOT_AUTHORIZED error format" do
    it "returns the expected error structure" do
      result = gql("query { users { id } }", user: empty_user)

      expect(result["errors"]).to be_an(Array)
      error = result["errors"].first
      expect(error["message"]).to eq("NOT_AUTHORIZED")
      expect(error["extensions"]).to eq("code" => "UNAUTHORIZED")
    end
  end
end
