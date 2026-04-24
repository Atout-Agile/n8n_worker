# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RolePermission, type: :model do
  describe 'validations' do
    let(:role)       { create(:role) }
    let(:permission) { create(:permission, :users_read) }

    it 'rejects a duplicate role/permission pair' do
      create(:role_permission, role: role, permission: permission)
      duplicate = build(:role_permission, role: role, permission: permission)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'Role#assign_permissions' do
    let!(:perm_a) { create(:permission, :users_read) }
    let!(:perm_b) { create(:permission, :tokens_read) }
    let(:role)    { create(:role).tap { |r| r.permissions << [ perm_a, perm_b ] } }
    let(:user)    { create(:user, role: role) }
    let!(:token)  { create(:api_token, user: user, permissions: [ perm_a, perm_b ]) }

    it 'replaces the permission set and cascades removals to tokens' do
      role.assign_permissions([ perm_b.id ])

      expect(role.reload.permissions).to contain_exactly(perm_b)
      expect(token.reload.permissions).to contain_exactly(perm_b)
    end

    it 'adds new permissions without touching tokens' do
      perm_c = create(:permission, :users_write)
      role.assign_permissions([ perm_a.id, perm_b.id, perm_c.id ])

      expect(role.reload.permissions).to include(perm_c)
      # token keeps its existing permissions untouched
      expect(token.reload.permissions).to contain_exactly(perm_a, perm_b)
    end

    it 'clears all permissions when called with an empty list' do
      role.assign_permissions([])

      expect(role.reload.permissions).to be_empty
      expect(token.reload.permissions).to be_empty
    end
  end

  describe 'cascade: removing a permission from a role revokes it from tokens' do
    let!(:perm)  { create(:permission, :users_read) }
    let(:role)   { create(:role).tap { |r| r.permissions << perm } }
    let(:user)   { create(:user, role: role) }
    let!(:token) { create(:api_token, user: user, permissions: [ perm ]) }

    it 'removes the permission from tokens belonging to users of that role' do
      expect(token.permissions).to include(perm)

      role.permissions.delete(perm)

      expect(token.reload.permissions).to be_empty
    end

    it 'does not affect tokens of users in other roles' do
      other_role  = create(:role).tap { |r| r.permissions << perm }
      other_user  = create(:user, role: other_role)
      other_token = create(:api_token, user: other_user, permissions: [ perm ])

      role.permissions.delete(perm)

      expect(other_token.reload.permissions).to include(perm)
    end

    it 'does not affect tokens that did not have the permission' do
      other_perm       = create(:permission, :tokens_read)
      role.permissions << other_perm
      token.permissions << other_perm

      role.permissions.delete(perm)   # only perm is removed from role

      expect(token.reload.permissions).to contain_exactly(other_perm)
    end
  end
end
