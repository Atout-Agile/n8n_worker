# frozen_string_literal: true
# Charger les dépendances
require_relative '../config/environment'
require 'simplecov'
require 'fileutils'
require 'rspec/rails'
require 'factory_bot'
require 'shoulda/matchers'
require 'spec_helper'

# Configuration SimpleCov
SimpleCov.start do
  coverage_dir 'coverage'
  
  enable_coverage :line
  primary_coverage :line
  refuse_coverage_drop
  
  # Filtrer les fichiers de base
  add_filter do |source_file|
    source_file.filename.include?('app/channels') ||
    source_file.filename.include?('app/jobs') ||
    source_file.filename.include?('app/mailers') ||
    source_file.filename.include?('app/graphql/types/base_') ||
    source_file.filename.include?('app/graphql/mutations/base_') ||
    source_file.filename.include?('/test/') ||
    source_file.filename.include?('/config/') ||
    source_file.filename.include?('/vendor/') ||
    source_file.filename.include?('/spec/')
  end

  # Grouper les fichiers
  add_group 'Models', 'app/models'
  add_group 'GraphQL', 'app/graphql'
  add_group 'JWT', 'app/lib/jwt'

  # Forcer un seul rapport
  at_exit do
    puts "\nGénération du rapport de couverture..."
    SimpleCov.result.format!
  end
end

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-1/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Configurer FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Charger automatiquement tous les fichiers de support
  Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

  config.before(:suite) do
    FileUtils.mkdir_p('tmp/screenshots')
  end
end

# Configurer Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
