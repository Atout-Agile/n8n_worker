# frozen_string_literal: true

require 'simplecov'

# Ignore les fichiers de config et les tests
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  
  # Grouper les fichiers pour le rapport
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'GraphQL', 'app/graphql'
  add_group 'Services', 'app/services'
  add_group 'Lib', 'app/lib'
end
