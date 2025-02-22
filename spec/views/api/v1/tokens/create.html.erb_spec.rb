# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v1/tokens/create', type: :view do
  let(:token) { build_stubbed(:api_token) }

  it 'renders token creation success message' do
    assign(:token, token)
    render
    expect(rendered).to include('Token créé avec succès')
    expect(rendered).to include(token.name)
  end
end
