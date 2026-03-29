# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v1/tokens/new', type: :view do
  let(:role)  { create(:role) }
  let(:token) { ApiToken.new }

  before do
    assign(:token, token)
    assign(:role_permissions, Permission.none)
  end

  it 'renders the creation form' do
    render
    expect(rendered).to include('New API Token')
    expect(rendered).to include('Token name')
    expect(rendered).to include('Create token')
  end

  it 'shows validation errors when present' do
    token.errors.add(:name, "can't be blank")
    render
    expect(rendered).to include("Name can&#39;t be blank")
  end

  it 'shows a message when the role has no permissions' do
    render
    expect(rendered).to include('Your role has no permissions assigned')
  end

  it 'shows role permissions as checkboxes' do
    perm = create(:permission, :users_read)
    assign(:role_permissions, Permission.where(id: perm.id))
    render
    expect(rendered).to include(perm.name)
    expect(rendered).to include("token[permission_ids][]")
  end
end
