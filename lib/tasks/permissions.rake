# frozen_string_literal: true

namespace :permissions do
  desc "Sync permissions declared via permission_required in GraphQL mutations/queries to the database"
  task sync: :environment do
    result = Permissions::SyncService.new.call

    puts "Permissions sync complete:"
    puts "  #{result[:created]} created"
    puts "  #{result[:updated]} updated (re-activated)"
    puts "  #{result[:deprecated]} deprecated"
  end
end
