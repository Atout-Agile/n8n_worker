# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  let(:role) { create(:role) }
  let(:user) { create(:user, role: role) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:token_digest) }
    # Note: expires_at validation is skipped because we have a before_validation callback
    # that automatically sets the value when it's blank

    describe 'uniqueness validation' do
      let!(:existing_token) { create(:api_token, user: user, name: 'Test Token') }

      it 'validates uniqueness of name scoped to user' do
        duplicate_token = build(:api_token, user: user, name: 'Test Token')
        expect(duplicate_token).not_to be_valid
        expect(duplicate_token.errors[:name]).to include('You already have a token with this name')
      end

      it 'allows same name for different users' do
        other_user = create(:user, role: role)
        token_with_same_name = build(:api_token, user: other_user, name: 'Test Token')
        expect(token_with_same_name).to be_valid
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:api_token_permissions).dependent(:destroy) }
    it { should have_many(:permissions).through(:api_token_permissions) }
  end

  describe 'permissions validation' do
    let(:role_perm) { create(:permission, :users_read) }
    let(:other_perm) { create(:permission, :tokens_read) }

    before { role.permissions << role_perm }

    it 'accepts a token with zero permissions' do
      token = build(:api_token, user: user)
      expect(token).to be_valid
    end

    it 'accepts a token with a valid subset of role permissions' do
      token = build(:api_token, user: user, permissions: [ role_perm ])
      expect(token).to be_valid
    end

    it 'rejects a token with a permission not in the role' do
      token = build(:api_token, user: user, permissions: [ other_perm ])
      expect(token).not_to be_valid
      expect(token.errors[:permissions]).to include(
        a_string_including('tokens:read')
      )
    end

    it 'rejects a token where only some permissions are invalid' do
      token = build(:api_token, user: user, permissions: [ role_perm, other_perm ])
      expect(token).not_to be_valid
    end
  end

  describe 'callbacks' do
    describe 'set_default_expiration' do
      it 'sets default expiration when not provided' do
        token = build(:api_token, expires_at: nil)
        token.valid? # Trigger callbacks

        expected_expiration = 30.days.from_now
        expect(token.expires_at).to be_within(1.second).of(expected_expiration)
      end

      it 'does not override provided expiration' do
        custom_expiration = 7.days.from_now
        token = build(:api_token, expires_at: custom_expiration)
        token.valid? # Trigger callbacks

        expect(token.expires_at).to be_within(1.second).of(custom_expiration)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:api_token)).to be_valid
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_token) { create(:api_token, user: user, expires_at: 1.day.from_now) }
      let!(:expired_token) { create(:api_token, user: user, expires_at: 1.day.ago) }

      it 'returns only non-expired tokens' do
        expect(described_class.active).to include(active_token)
        expect(described_class.active).not_to include(expired_token)
      end
    end
  end

  describe 'class methods' do
    describe '.generate_for_user' do
      it 'creates a new token with raw token' do
        token = ApiToken.generate_for_user(user, 'Test Token')

        expect(token).to be_persisted
        expect(token.name).to eq('Test Token')
        expect(token.user).to eq(user)
        expect(token.token_digest).to be_present
        expect(token).to respond_to(:raw_token)
        expect(token.raw_token).to be_present
        expect(token.raw_token.length).to eq(64) # 32 bytes in hex
      end

      it 'accepts custom expiration days' do
        token = ApiToken.generate_for_user(user, 'Test Token', expires_in_days: 7)

        expected_expiration = 7.days.from_now
        expect(token.expires_at).to be_within(1.minute).of(expected_expiration)
      end

      it 'returns invalid token object on validation error' do
        token = ApiToken.generate_for_user(user, '') # Invalid name

        expect(token).not_to be_persisted
        expect(token.errors).not_to be_empty
      end

      it 'generates unique token digests' do
        token1 = ApiToken.generate_for_user(user, 'Token 1')
        token2 = ApiToken.generate_for_user(user, 'Token 2')

        expect(token1.token_digest).not_to eq(token2.token_digest)
        expect(token1.raw_token).not_to eq(token2.raw_token)
      end
    end

    describe '.find_by_token' do
      let!(:token) { ApiToken.generate_for_user(user, 'Test Token') }

      it 'finds token by raw token value' do
        found_token = ApiToken.find_by_token(token.raw_token)
        expect(found_token).to eq(token)
      end

      it 'returns nil for non-existent token' do
        expect(ApiToken.find_by_token('non_existent_token')).to be_nil
      end

      it 'returns nil for a blank token' do
        expect(ApiToken.find_by_token('')).to be_nil
        expect(ApiToken.find_by_token(nil)).to be_nil
      end

      it 'uses constant-time comparison (secure_compare)' do
        allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original
        ApiToken.find_by_token(token.raw_token)
        expect(ActiveSupport::SecurityUtils).to have_received(:secure_compare)
      end
    end
  end

  describe 'instance methods' do
    let(:active_token) { create(:api_token, user: user, expires_at: 1.day.from_now) }
    let(:expired_token) { create(:api_token, user: user, expires_at: 1.day.ago) }

    describe '#active?' do
      it 'returns true for non-expired tokens' do
        expect(active_token).to be_active
      end

      it 'returns false for expired tokens' do
        expect(expired_token).not_to be_active
      end
    end

    describe '#expired?' do
      it 'returns false for non-expired tokens' do
        expect(active_token).not_to be_expired
      end

      it 'returns true for expired tokens' do
        expect(expired_token).to be_expired
      end
    end

    describe '#touch_last_used!' do
      it 'updates last_used_at timestamp' do
        # Vérifier que last_used_at était initialement nil
        expect(active_token.last_used_at).to be_nil

        # Appeler la méthode
        active_token.touch_last_used!

        # Vérifier que last_used_at a été mis à jour avec une valeur récente
        expect(active_token.reload.last_used_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#expires_in_words' do
      it 'returns "Expired" for expired tokens' do
        expect(expired_token.expires_in_words).to eq('Expired')
      end

      it 'returns human readable time for active tokens' do
        token = create(:api_token, user: user, expires_at: 2.days.from_now)
        expect(token.expires_in_words).to include('2 days')
      end
    end
  end
end
