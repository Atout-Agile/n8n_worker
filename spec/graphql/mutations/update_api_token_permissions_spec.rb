# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::UpdateApiTokenPermissions do
  let!(:tokens_write) { create(:permission, :tokens_write) }
  let!(:tokens_read)  { create(:permission, :tokens_read) }
  let!(:users_read)   { create(:permission, :users_read) }

  let(:role) { create(:role).tap { |r| r.permissions << [ tokens_write, tokens_read ] } }
  let(:user) { create(:user, role: role) }
  let!(:api_token) { create(:api_token, user: user, permissions: [ tokens_write ]) }

  let(:mutation) do
    <<~GQL
      mutation UpdatePerms($id: ID!, $permissionIds: [ID!]!) {
        updateApiTokenPermissions(id: $id, permissionIds: $permissionIds) {
          apiToken { id permissions { name } }
          errors
        }
      }
    GQL
  end

  def run(token_id:, permission_ids:, current_user: user, current_token: nil)
    N8nWorkerSchema.execute(
      mutation,
      variables: { id: token_id.to_s, permissionIds: permission_ids.map(&:to_s) },
      context: { current_user: current_user, current_token: current_token, operation_name: "UpdatePerms" }
    ).to_h
  end

  context "with tokens:write permission" do
    it "updates the token permissions" do
      result = run(token_id: api_token.id, permission_ids: [ tokens_read.id ])
      names = result.dig("data", "updateApiTokenPermissions", "apiToken", "permissions").map { |p| p["name"] }
      expect(names).to contain_exactly("tokens:read")
      expect(api_token.reload.permissions).to contain_exactly(tokens_read)
    end

    it "clears permissions when an empty list is given" do
      result = run(token_id: api_token.id, permission_ids: [])
      expect(result.dig("data", "updateApiTokenPermissions", "errors")).to be_empty
      expect(api_token.reload.permissions).to be_empty
    end

    it "ignores permission IDs outside the user's role" do
      result = run(token_id: api_token.id, permission_ids: [ users_read.id ])
      expect(result.dig("data", "updateApiTokenPermissions", "errors")).to be_empty
      # users_read is not in the role → silently ignored → token ends up with no permissions
      expect(api_token.reload.permissions).to be_empty
    end

    it "returns an error for an unknown token" do
      result = run(token_id: 99_999, permission_ids: [])
      expect(result.dig("data", "updateApiTokenPermissions", "errors")).to include("Token not found")
    end

    it "cannot update another user's token" do
      other_token = create(:api_token, user: create(:user, role: role))
      result = run(token_id: other_token.id, permission_ids: [])
      expect(result.dig("data", "updateApiTokenPermissions", "errors")).to include("Token not found")
    end
  end

  context "without tokens:write permission" do
    let(:role_no_write) { create(:role) }
    let(:user_no_write) { create(:user, role: role_no_write) }

    it "returns NOT_AUTHORIZED" do
      result = run(token_id: api_token.id, permission_ids: [], current_user: user_no_write)
      expect(result.dig("errors", 0, "message")).to eq("NOT_AUTHORIZED")
    end
  end
end
