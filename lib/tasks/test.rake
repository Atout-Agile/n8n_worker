# frozen_string_literal: true

namespace :test do
  desc 'Run tests with coverage'
  task coverage: :environment do
    # Forcer l'environnement de test
    ENV['RAILS_ENV'] = 'test'
    Rails.env = 'test'

    # NOTE: Cette configuration de SimpleCov est redondante et cause des problèmes
    # car SimpleCov est déjà configuré dans spec/rails_helper.rb
    # require 'simplecov'
    #
    # # Configurer SimpleCov
    # SimpleCov.start 'rails' do
    #   add_filter '/spec/'
    #   add_filter '/config/'
    #   
    #   add_group 'Controllers', 'app/controllers'
    #   add_group 'Models', 'app/models'
    #   add_group 'GraphQL', 'app/graphql'
    #   add_group 'Services', 'app/services'
    #   add_group 'Lib', 'app/lib'
    # end

    # Préparer la base de test
    Rake::Task['db:environment:set'].invoke('RAILS_ENV=test')
    Rake::Task['db:test:prepare'].invoke

    # Lancer RSpec
    success = system('bundle exec rspec')

    # Afficher le chemin du rapport (qu'il y ait des erreurs ou non)
    puts "\nRapport de couverture :"
    puts "------------------------"
    puts "Copiez ce chemin dans votre navigateur Windows :"
    puts "\\\\wsl$\\#{ENV['WSL_DISTRO_NAME']}#{Rails.root}/coverage/index.html"
    puts "------------------------"

    # Sortir avec le code d'erreur approprié
    exit(success ? 0 : 1)
  end
end 