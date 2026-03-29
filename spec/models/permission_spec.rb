# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permission, type: :model do
  subject { build(:permission, :users_read) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_uniqueness_of(:name) }

    describe 'name format' do
      it 'accepts valid resource:read format' do
        expect(build(:permission, name: 'users:read')).to be_valid
      end

      it 'accepts valid resource:write format' do
        expect(build(:permission, name: 'users:write')).to be_valid
      end

      it 'accepts names with underscores in resource' do
        expect(build(:permission, name: 'api_tokens:read')).to be_valid
      end

      it 'rejects names without colon separator' do
        perm = build(:permission, name: 'usersread')
        expect(perm).not_to be_valid
        expect(perm.errors[:name]).to include("must follow format 'resource:action' (e.g. users:read)")
      end

      it 'rejects names with invalid action' do
        perm = build(:permission, name: 'users:delete')
        expect(perm).not_to be_valid
        expect(perm.errors[:name]).to include("must follow format 'resource:action' (e.g. users:read)")
      end

      it 'rejects names with uppercase' do
        perm = build(:permission, name: 'Users:read')
        expect(perm).not_to be_valid
        expect(perm.errors[:name]).to include("must follow format 'resource:action' (e.g. users:read)")
      end

      it 'rejects blank name' do
        perm = build(:permission, name: '')
        expect(perm).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { should have_many(:role_permissions).dependent(:destroy) }
    it { should have_many(:roles).through(:role_permissions) }
    it { should have_many(:api_token_permissions).dependent(:destroy) }
    it { should have_many(:api_tokens).through(:api_token_permissions) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_perm) { create(:permission) }
      let!(:deprecated_perm) { create(:permission, :deprecated) }

      it 'returns only non-deprecated permissions' do
        expect(described_class.active).to include(active_perm)
        expect(described_class.active).not_to include(deprecated_perm)
      end
    end
  end

  describe 'instance methods' do
    let(:permission) { build(:permission, :users_read) }

    describe '#resource' do
      it 'returns the resource part of the name' do
        expect(permission.resource).to eq('users')
      end
    end

    describe '#action' do
      it 'returns the action part of the name' do
        expect(permission.action).to eq('read')
      end
    end
  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:permission)).to be_valid
    end

    it 'has a valid users_read trait' do
      expect(build(:permission, :users_read)).to be_valid
    end

    it 'has a valid users_write trait' do
      expect(build(:permission, :users_write)).to be_valid
    end

    it 'has a valid tokens_read trait' do
      expect(build(:permission, :tokens_read)).to be_valid
    end

    it 'has a valid tokens_write trait' do
      expect(build(:permission, :tokens_write)).to be_valid
    end

    it 'has a valid deprecated trait' do
      perm = build(:permission, :deprecated)
      expect(perm).to be_valid
      expect(perm.deprecated).to be true
    end
  end
end
