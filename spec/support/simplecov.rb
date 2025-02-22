# frozen_string_literal: true

require 'simplecov'

COVERED_FILES = [
  'app/models/user.rb',
  'app/models/role.rb',
  'app/models/api_token.rb',
  'app/graphql/mutations/login.rb',
  'app/graphql/types/user_type.rb',
  'app/graphql/types/role_type.rb',
  'app/lib/jwt/authenticate_graphql_request.rb',
  'app/lib/jwt/json_web_token.rb'
].freeze

SimpleCov.start do
  # Ne suivre que les fichiers listés
  track_files COVERED_FILES

  # Grouper les fichiers
  add_group 'Models' do |file|
    COVERED_FILES.include?(file.filename) && file.filename.start_with?('app/models')
  end

  add_group 'GraphQL' do |file|
    COVERED_FILES.include?(file.filename) && file.filename.start_with?('app/graphql')
  end

  add_group 'JWT' do |file|
    COVERED_FILES.include?(file.filename) && file.filename.start_with?('app/lib/jwt')
  end

  # Ignorer tout ce qui n'est pas dans la liste
  add_filter do |file|
    !COVERED_FILES.include?(file.filename)
  end

  enable_coverage :line
  minimum_coverage 80
end
