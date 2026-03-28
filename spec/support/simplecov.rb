# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  # Grouper les fichiers
  add_group 'Models', 'app/models'
  add_group 'GraphQL', 'app/graphql'
  add_group 'JWT', 'app/lib/jwt'
  add_group 'Controllers', 'app/controllers'

  # Filtrer les fichiers non pertinents
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/'
  add_filter '/bin/'
  add_filter '/lib/tasks/'

  enable_coverage :line
  primary_coverage :line
end
