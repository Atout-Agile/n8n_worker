# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :request do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }

  describe '#current_user' do
    context 'when user is not logged in' do
      it 'returns nil when no token in session' do
        get dashboard_path
        
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe '#authenticate_user!' do
    context 'when user is not authenticated' do
      it 'redirects to login with alert message' do
        get dashboard_path
        
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq('Please log in to access this page.')
      end
    end
  end

  describe 'private methods' do
    let(:controller) { ApplicationController.new }

    describe '#decode_token' do
      it 'decodes JWT token' do
        token = JsonWebToken.encode(user_id: user.id)
        result = controller.send(:decode_token, token)
        expect(result[:user_id]).to eq(user.id)
      end
    end

  end
end 