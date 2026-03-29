# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe Permissions::SyncService do
  # Write fixture files to a temp dir and pass them as scan_paths
  def with_fixture_files(files)
    Dir.mktmpdir do |dir|
      files.each do |name, content|
        path = File.join(dir, name)
        File.write(path, content)
      end
      yield Dir.glob(File.join(dir, '**/*.rb'))
    end
  end

  def service_with_files(files)
    with_fixture_files(files) do |paths|
      described_class.new(scan_paths: paths)
    end
  end

  # Returns a service whose scan_paths point to the temp files, keeping the
  # block open while the service is called.
  def call_with_files(files)
    with_fixture_files(files) do |paths|
      described_class.new(scan_paths: paths).call
    end
  end

  describe '#call' do
    context 'when code declares new permissions' do
      it 'creates missing permissions in the database' do
        result = call_with_files(
          'mutation.rb' => 'permission_required "users:read"'
        )

        expect(result[:created]).to eq(1)
        expect(Permission.find_by(name: 'users:read')).to be_present
      end

      it 'sets a generated description on created permissions' do
        call_with_files('mutation.rb' => 'permission_required "users:write"')

        perm = Permission.find_by(name: 'users:write')
        expect(perm.description).to eq('Write access to users')
      end

      it 'creates permissions from multiple files' do
        result = call_with_files(
          'mutations.rb' => 'permission_required "users:write"',
          'queries.rb'   => 'permission_required "users:read"'
        )

        expect(result[:created]).to eq(2)
        expect(Permission.count).to eq(2)
      end
    end

    context 'idempotence' do
      it 'does not duplicate a permission that already exists' do
        create(:permission, :users_read)

        result = call_with_files('mutation.rb' => 'permission_required "users:read"')

        expect(result[:created]).to eq(0)
        expect(Permission.where(name: 'users:read').count).to eq(1)
      end

      it 'returns zeros when nothing has changed' do
        create(:permission, :users_read)
        result1 = call_with_files('mutation.rb' => 'permission_required "users:read"')
        result2 = call_with_files('mutation.rb' => 'permission_required "users:read"')

        expect(result1[:created]).to eq(0)
        expect(result2).to eq({ created: 0, updated: 0, deprecated: 0 })
      end
    end

    context 'when a permission disappears from code' do
      it 'marks it deprecated without deleting it' do
        create(:permission, :users_read)

        result = call_with_files('mutation.rb' => '# no permissions here')

        expect(result[:deprecated]).to eq(1)
        perm = Permission.find_by(name: 'users:read')
        expect(perm).to be_present
        expect(perm).to be_deprecated
      end

      it 'does not deprecate a permission that is still present' do
        create(:permission, :users_read)
        create(:permission, :users_write)

        call_with_files('mutation.rb' => 'permission_required "users:read"')

        expect(Permission.find_by(name: 'users:read')).not_to be_deprecated
        expect(Permission.find_by(name: 'users:write')).to be_deprecated
      end
    end

    context 'when a previously deprecated permission reappears in code' do
      it 'un-deprecates it and counts it as updated' do
        create(:permission, :users_read, deprecated: true)

        result = call_with_files('mutation.rb' => 'permission_required "users:read"')

        expect(result[:updated]).to eq(1)
        expect(result[:created]).to eq(0)
        expect(Permission.find_by(name: 'users:read')).not_to be_deprecated
      end
    end

    context 'summary metrics' do
      it 'reports correct counts when creating, updating, and deprecating in one run' do
        create(:permission, :users_write)                     # stays in code → unchanged
        create(:permission, :tokens_read, deprecated: true)  # back in code → updated
        create(:permission, :tokens_write)                    # removed from code → deprecated

        result = call_with_files(
          'file.rb' => <<~RUBY
            permission_required "users:write"
            permission_required "users:read"
            permission_required "tokens:read"
          RUBY
        )

        expect(result[:created]).to eq(1)    # users:read is new
        expect(result[:updated]).to eq(1)    # tokens:read re-activated
        expect(result[:deprecated]).to eq(1) # tokens:write removed
      end
    end

    context 'when no files match the scan paths' do
      it 'deprecates all existing permissions' do
        create(:permission, :users_read)

        result = described_class.new(scan_paths: []).call

        expect(result[:deprecated]).to eq(1)
        expect(Permission.find_by(name: 'users:read')).to be_deprecated
      end
    end
  end
end
