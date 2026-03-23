# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v1/tokens/create', type: :view do
  context 'when token was just created (persisted)' do
    let(:token) { build_stubbed(:api_token) }

    it 'renders token creation success message with name and expiration' do
      assign(:token, token)
      render
      expect(rendered).to include('Token Created Successfully')
      expect(rendered).to include(token.name)
    end

    it 'shows the raw token when available' do
      token.define_singleton_method(:raw_token) { 'rawsecrettoken123' }
      assign(:token, token)
      render
      expect(rendered).to include('rawsecrettoken123')
      expect(rendered).to include("won't be shown again")
    end
  end

  context 'when displaying the creation form (not yet persisted)' do
    let(:token) { ApiToken.new }

    it 'renders the creation form' do
      assign(:token, token)
      render
      expect(rendered).to include('Create New API Token')
      expect(rendered).to include('Token Name')
      expect(rendered).to include('Create Token')
    end

    it 'shows validation errors when present' do
      token.errors.add(:name, "can't be blank")
      assign(:token, token)
      render
      expect(rendered).to include("Name can&#39;t be blank")
    end
  end
end
