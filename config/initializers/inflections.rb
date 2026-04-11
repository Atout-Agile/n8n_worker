# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Register "JWT" as an acronym so Zeitwerk expects app/lib/jwt/*.rb to
# define constants under the JWT:: module (all-caps), not Jwt:: (camelcase).
# Without this, Rails.application.eager_load! fails on
# app/lib/jwt/authenticate_graphql_request.rb which defines
# JWT::AuthenticateGraphqlRequest.
#
# @since 2026-04-11
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "JWT"
end
