# frozen_string_literal: true

module GraphQLHelper
  def graphql_request(query:, variables: {}, current_user: nil)
    # Configurer l'en-tête pour GraphQL
    headers = { 'CONTENT_TYPE' => 'application/json' }
    
    # Ajouter l'authentification si nécessaire
    if current_user
      token = JsonWebToken.encode(user_id: current_user.id)
      headers['Authorization'] = "Bearer #{token}"
    end

    # Faire la requête
    post '/graphql',
         params: { query: query, variables: variables }.to_json,
         headers: headers
  end
end

RSpec.configure do |config|
  # Inclure le helper pour les tests GraphQL et request
  config.include GraphQLHelper, type: :request
  config.include GraphQLHelper, type: :graphql
end 