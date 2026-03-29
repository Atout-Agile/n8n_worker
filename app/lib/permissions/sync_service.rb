# frozen_string_literal: true

module Permissions
  # Synchronizes the Permission table with permissions declared in GraphQL mutation
  # and query source files via +permission_required+.
  #
  # - Creates permissions present in the code but absent from the database.
  # - Un-deprecates permissions that were deprecated but have reappeared in the code.
  # - Marks permissions as +deprecated: true+ when they are no longer declared in
  #   any scanned file (without deleting them).
  # - Is idempotent: running it multiple times produces the same result.
  #
  # @example From a rake task
  #   result = Permissions::SyncService.new.call
  #   puts "#{result[:created]} created, #{result[:updated]} updated, #{result[:deprecated]} deprecated"
  #
  # @example With custom scan paths (useful for tests)
  #   result = Permissions::SyncService.new(scan_paths: ['/tmp/fixtures/**/*.rb']).call
  #
  # @see lib/tasks/permissions.rake
  # @since 2026-03-28
  class SyncService
    # Pattern matching: permission_required "users:read" or permission_required 'users:read'
    PERMISSION_PATTERN = /permission_required\s+["']([a-z_0-9]+:(read|write))["']/

    # @param scan_paths [Array<String>] Glob patterns to scan. Defaults to app/graphql mutations + queries.
    def initialize(scan_paths: nil)
      @scan_paths = scan_paths || default_scan_paths
    end

    # Runs the sync and returns a summary hash.
    #
    # @return [Hash] with keys :created, :updated, :deprecated (all Integer)
    def call
      scanned_names = scan_permissions
      sync_to_database(scanned_names)
    end

    private

    # @return [Array<String>] unique permission names found in scanned files
    def scan_permissions
      @scan_paths
        .flat_map { |pattern| Dir.glob(pattern) }
        .flat_map { |file| extract_permissions(File.read(file)) }
        .uniq
    end

    # @param content [String] file content
    # @return [Array<String>] permission names found in this file
    def extract_permissions(content)
      content.scan(PERMISSION_PATTERN).map(&:first)
    end

    # @param scanned_names [Array<String>]
    # @return [Hash]
    def sync_to_database(scanned_names)
      created = 0
      updated = 0
      deprecated = 0

      scanned_names.each do |name|
        perm = Permission.find_or_initialize_by(name: name)

        if perm.new_record?
          perm.description = description_for(name)
          perm.deprecated  = false
          perm.save!
          created += 1
        elsif perm.deprecated?
          perm.update!(deprecated: false)
          updated += 1
        end
      end

      Permission.where.not(name: scanned_names).where(deprecated: false).find_each do |perm|
        perm.update!(deprecated: true)
        deprecated += 1
      end

      { created: created, updated: updated, deprecated: deprecated }
    end

    # Generates a human-readable description from a permission name.
    #
    # @param name [String] e.g. "users:read"
    # @return [String] e.g. "Read access to users"
    def description_for(name)
      resource, action = name.split(":")
      "#{action.capitalize} access to #{resource}"
    end

    def default_scan_paths
      [
        Rails.root.join("app/graphql/mutations/**/*.rb").to_s,
        Rails.root.join("app/graphql/queries/**/*.rb").to_s
      ]
    end
  end
end
