# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::RolesController, type: :request do
  let!(:admin_role)  { create(:role, name: "admin", description: "Administrator") }
  let!(:other_role)  { create(:role) }
  let(:admin_user)  { create(:user, role: admin_role) }
  let(:normal_user) { create(:user, role: other_role) }

  let!(:perm_users_read)  { create(:permission, :users_read) }
  let!(:perm_tokens_write) { create(:permission, :tokens_write) }
  let!(:perm_deprecated)  { create(:permission, name: "old:read", description: "Deprecated", deprecated: true) }

  # Signs in the given user by posting to the sessions endpoint.
  def sign_in(user)
    token = JsonWebToken.encode(user_id: user.id)
    post '/sessions', params: { email: user.email, password: 'password123' }
  end

  # Sets the session JWT directly without going through the login form.
  def set_session_for(user)
    token = JsonWebToken.encode(user_id: user.id)
    post '/sessions', params: { email: user.email, password: 'password123' }
  end

  shared_context 'signed in as admin' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
    end
  end

  shared_context 'signed in as normal user' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(normal_user)
    end
  end

  describe 'GET /admin/roles' do
    context 'when not logged in' do
      it 'redirects to login' do
        get admin_roles_path
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when logged in as a non-admin' do
      include_context 'signed in as normal user'

      it 'redirects to dashboard with an access denied alert' do
        get admin_roles_path
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end

    context 'when logged in as admin' do
      include_context 'signed in as admin'

      it 'returns 200 and lists roles' do
        get admin_roles_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(admin_role.name)
        expect(response.body).to include(other_role.name)
      end
    end
  end

  describe 'GET /admin/roles/:id/edit' do
    context 'when not logged in' do
      it 'redirects to login' do
        get edit_admin_role_path(admin_role)
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when logged in as a non-admin' do
      include_context 'signed in as normal user'

      it 'redirects to dashboard' do
        get edit_admin_role_path(other_role)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when logged in as admin' do
      include_context 'signed in as admin'

      it 'returns 200 and shows the permission form' do
        get edit_admin_role_path(other_role)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(perm_users_read.name)
        expect(response.body).to include(perm_tokens_write.name)
      end

      it 'shows deprecated permissions as disabled' do
        get edit_admin_role_path(other_role)
        expect(response.body).to include('deprecated')
        expect(response.body).to include("disabled")
      end

      it 'shows checked state for already-assigned permissions' do
        other_role.permissions << perm_users_read
        get edit_admin_role_path(other_role)
        expect(response.body).to match(/checked.*perm_#{perm_users_read.id}|perm_#{perm_users_read.id}.*checked/m)
      end
    end
  end

  describe 'PATCH /admin/roles/:id' do
    context 'when not logged in' do
      it 'redirects to login' do
        patch admin_role_path(other_role), params: { role: { permission_ids: [] } }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when logged in as a non-admin' do
      include_context 'signed in as normal user'

      it 'redirects to dashboard' do
        patch admin_role_path(other_role), params: { role: { permission_ids: [] } }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when logged in as admin' do
      include_context 'signed in as admin'

      it 'assigns selected permissions to the role' do
        expect {
          patch admin_role_path(other_role),
            params: { role: { permission_ids: [ perm_users_read.id, perm_tokens_write.id ] } }
        }.to change { other_role.reload.permissions.count }.from(0).to(2)

        expect(response).to redirect_to(admin_roles_path)
        expect(flash[:notice]).to include(other_role.name)
      end

      it 'removes permissions not included in the submission' do
        other_role.permissions << perm_users_read
        expect {
          patch admin_role_path(other_role),
            params: { role: { permission_ids: [] } }
        }.to change { other_role.reload.permissions.count }.from(1).to(0)
      end

      it 'ignores deprecated permissions even if submitted' do
        patch admin_role_path(other_role),
          params: { role: { permission_ids: [ perm_deprecated.id ] } }

        expect(other_role.reload.permissions).not_to include(perm_deprecated)
      end

      it 'handles missing permission_ids param (all unchecked)' do
        other_role.permissions << perm_users_read
        patch admin_role_path(other_role), params: { role: {} }
        expect(other_role.reload.permissions).to be_empty
      end
    end
  end
end
