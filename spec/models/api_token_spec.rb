# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:token_digest) }
    it { should validate_presence_of(:expires_at) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:api_token)).to be_valid
    end
  end

  describe 'scopes' do
    context 'active' do
      let(:role) { create(:role) }
      let(:user1) { create(:user, role: role) }
      let(:user2) { create(:user, role: role) }
      
      it 'returns only non-expired tokens' do
        expired_token = create(:api_token, user: user1, expires_at: 1.day.ago)
        active_token = create(:api_token, user: user2, expires_at: 1.day.from_now)
        
        expect(described_class.active).to include(active_token)
        expect(described_class.active).not_to include(expired_token)
      end
    end
  end
end
