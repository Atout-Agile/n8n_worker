# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserAssistantConfigPolicy do
  let(:user) { create(:user) }

  it 'denies read without permission' do
    expect(described_class.new(user: user, token: nil).read?).to be false
  end

  it 'grants read when permission is active' do
    perm = create(:permission, name: 'assistant_config:read')
    user.role.permissions << perm
    expect(described_class.new(user: user, token: nil).read?).to be true
  end

  it 'grants write when permission is active' do
    perm = create(:permission, name: 'assistant_config:write')
    user.role.permissions << perm
    expect(described_class.new(user: user, token: nil).write?).to be true
  end
end
