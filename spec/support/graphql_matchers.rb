# frozen_string_literal: true

# Charger la gem seulement si elle est disponible
begin
  require 'rspec-graphql_matchers'
  RSpec.configure do |config|
    config.include RSpec::GraphqlMatchers
  end
rescue LoadError
  # La gem n'est pas disponible, on ignore
  puts "Warning: rspec-graphql_matchers not available"
end
