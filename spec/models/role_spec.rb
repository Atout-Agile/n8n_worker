# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:description) }
  end

  describe 'associations' do
    it { should have_many(:users).dependent(:restrict_with_error) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:role)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:role, :admin)).to be_valid
    end

    it 'has a valid user factory' do
      expect(build(:role, :user)).to be_valid
    end
  end
end
