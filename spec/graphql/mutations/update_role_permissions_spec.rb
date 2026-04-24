# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::UpdateRolePermissions do
  let!(:users_read)   { create(:permission, :users_read) }
  let!(:tokens_read)  { create(:permission, :tokens_read) }
  let!(:deprecated)   { create(:permission, name: "old:read", description: "Deprecated", deprecated: true) }

  let(:roles_write)   { create(:permission, name: "roles:write", description: "Manage roles") }
  let(:role)          { create(:role).tap { |r| r.permissions << roles_write } }
  let(:user)          { create(:user, role: role) }
  let(:target_role)   { create(:role) }

  let(:mutation) do
    <<~GQL
      mutation UpdateRolePerms($roleId: ID!, $permissionIds: [ID!]!) {
        updateRolePermissions(roleId: $roleId, permissionIds: $permissionIds) {
          role { id name permissions { name } }
          errors
        }
      }
    GQL
  end

  def run(role_id:, permission_ids:, current_user: user, current_token: nil)
    N8nWorkerSchema.execute(
      mutation,
      variables: { roleId: role_id.to_s, permissionIds: permission_ids.map(&:to_s) },
      context: { current_user: current_user, current_token: current_token, operation_name: "UpdateRolePerms" }
    ).to_h
  end

  context "with roles:write permission" do
    it "assigns the selected permissions to the role" do
      result = run(role_id: target_role.id, permission_ids: [ users_read.id, tokens_read.id ])
      names = result.dig("data", "updateRolePermissions", "role", "permissions").map { |p| p["name"] }
      expect(names).to contain_exactly("users:read", "tokens:read")
      expect(target_role.reload.permissions).to contain_exactly(users_read, tokens_read)
    end

    it "clears all permissions when an empty list is given" do
      target_role.permissions << users_read
      result = run(role_id: target_role.id, permission_ids: [])
      expect(result.dig("data", "updateRolePermissions", "errors")).to be_empty
      expect(target_role.reload.permissions).to be_empty
    end

    it "ignores deprecated permission IDs" do
      result = run(role_id: target_role.id, permission_ids: [ deprecated.id ])
      expect(result.dig("data", "updateRolePermissions", "errors")).to be_empty
      expect(target_role.reload.permissions).to be_empty
    end

    it "returns an error for an unknown role" do
      result = run(role_id: 99_999, permission_ids: [])
      expect(result.dig("data", "updateRolePermissions", "errors")).to include("Role not found")
    end
  end

  context "without roles:write permission" do
    let(:empty_role) { create(:role) }
    let(:unprivileged) { create(:user, role: empty_role) }

    it "returns NOT_AUTHORIZED" do
      result = run(role_id: target_role.id, permission_ids: [], current_user: unprivileged)
      expect(result.dig("errors", 0, "message")).to eq("NOT_AUTHORIZED")
    end
  end
end
