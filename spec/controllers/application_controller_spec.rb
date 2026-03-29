# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    def index
      render json: { current_user_id: current_user&.id }
    end
  end

  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }

  describe '#current_user' do
    context 'when no token in session' do
      it 'returns nil' do
        get :index

        json = JSON.parse(response.body)
        expect(json['current_user_id']).to be_nil
      end
    end

    context 'when token exists in session' do
      before { session[:jwt_token] = token }

      it 'returns the user matching the token' do
        get :index

        json = JSON.parse(response.body)
        expect(json['current_user_id']).to eq(user.id)
      end

      it 'returns nil when the user_id in the token does not exist in DB' do
        session[:jwt_token] = JsonWebToken.encode(user_id: 999_999)
        get :index

        json = JSON.parse(response.body)
        expect(json['current_user_id']).to be_nil
      end
    end

    context 'when JWT decode fails' do
      before { session[:jwt_token] = 'invalid_token' }

      it 'returns nil and logs the error' do
        expect(Rails.logger).to receive(:error).with(/Error fetching current user/)

        get :index

        json = JSON.parse(response.body)
        expect(json['current_user_id']).to be_nil
      end
    end
  end
end
