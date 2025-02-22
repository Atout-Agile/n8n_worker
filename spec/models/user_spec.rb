# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }  # Utiliser la factory avec un rôle par défaut
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password).on(:create) }
    it { should validate_length_of(:password).is_at_least(8).on(:create) }
  end

  describe 'associations' do
    it { should belong_to(:role) }
    it { should have_many(:api_tokens).dependent(:destroy) }
  end

  describe 'secure password' do
    it { should have_secure_password }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:user, :admin)).to be_valid
    end

    it 'creates associated api_token with trait' do
      user = create(:user, :with_api_token)
      expect(user.api_tokens).to exist
    end
  end
end
