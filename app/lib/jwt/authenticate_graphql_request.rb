# frozen_string_literal: true

module JWT
  class AuthenticateGraphqlRequest
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      
      # Skip authentication for GraphiQL en développement
      return @app.call(env) if development_graphiql_request?(request)

      token = extract_token(request)
      
      if token.nil?
        return unauthorized_response("Token d'authentification manquant")
      end

      begin
        payload = JsonWebToken.decode(token)
        env['jwt.payload'] = payload
        @app.call(env)
      rescue JWT::VerificationError, JWT::ExpiredSignature => e
        unauthorized_response(e.message)
      end
    end

    private

    def extract_token(request)
      # Extrait le token du header Authorization
      auth_header = request.headers['Authorization']
      return nil unless auth_header
      
      # Format attendu: "Bearer <token>"
      auth_header.split(' ')[1]
    end

    def unauthorized_response(message)
      [
        401,
        { 'Content-Type' => 'application/json' },
        [{ error: message }.to_json]
      ]
    end

    def development_graphiql_request?(request)
      return false unless Rails.env.development?
      
      request.path == '/graphiql' || 
        (request.path == '/graphql' && request.referer&.include?('/graphiql'))
    end
  end
end 