# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v1/tokens/new', type: :view do
  let(:token) { ApiToken.new }

  it 'renders the creation form' do
    assign(:token, token)
    render
    expect(rendered).to include('New API Token')
    expect(rendered).to include('Token name')
    expect(rendered).to include('Create token')
  end

  it 'shows validation errors when present' do
    token.errors.add(:name, "can't be blank")
    assign(:token, token)
    render
    expect(rendered).to include("Name can&#39;t be blank")
  end
end
