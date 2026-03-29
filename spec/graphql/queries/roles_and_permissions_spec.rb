# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "roles and permissions queries" do
  let!(:roles_read_perm)  { create(:permission, name: "roles:read",  description: "Read roles") }
  let!(:users_read_perm)  { create(:permission, :users_read) }

  let(:role) { create(:role).tap { |r| r.permissions << roles_read_perm } }
  let(:user) { create(:user, role: role) }

  def gql(query_str, current_user: user)
    N8nWorkerSchema.execute(query_str, context: { current_user: current_user, current_token: nil }).to_h
  end

  describe "query { roles }" do
    it "returns all roles with permissions for users with roles:read" do
      result = gql("query { roles { id name permissions { name } } }")
      expect(result.dig("data", "roles")).to be_an(Array)
      names = result["data"]["roles"].map { |r| r["name"] }
      expect(names).to include(role.name)
    end

    it "excludes deprecated permissions from role.permissions" do
      deprecated = create(:permission, name: "old:write", description: "Old", deprecated: true)
      role.permissions << deprecated

      result = gql("query { roles { name permissions { name } } }")
      role_data = result["data"]["roles"].find { |r| r["name"] == role.name }
      perm_names = role_data["permissions"].map { |p| p["name"] }

      expect(perm_names).not_to include("old:write")
      expect(perm_names).to include("roles:read")
    end

    it "returns NOT_AUTHORIZED without roles:read" do
      unprivileged = create(:user, role: create(:role))
      result = gql("query { roles { id } }", current_user: unprivileged)
      expect(result.dig("errors", 0, "message")).to eq("NOT_AUTHORIZED")
    end
  end

  describe "query { permissions }" do
    it "returns non-deprecated permissions for users with roles:read" do
      deprecated = create(:permission, name: "old:read", description: "Old", deprecated: true)
      result = gql("query { permissions { id name deprecated } }")
      names = result["data"]["permissions"].map { |p| p["name"] }
      expect(names).to include("roles:read", "users:read")
      expect(names).not_to include("old:read")
    end

    it "returns NOT_AUTHORIZED without roles:read" do
      unprivileged = create(:user, role: create(:role))
      result = gql("query { permissions { id } }", current_user: unprivileged)
      expect(result.dig("errors", 0, "message")).to eq("NOT_AUTHORIZED")
    end
  end
end
