# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user_from_token || current_user,
    }
    result = N8nWorkerSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end

  def current_user_from_token
    # Extraire le token du header Authorization
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    # Format attendu: "Bearer <token>"
    token = auth_header.split(' ')[1]
    return nil unless token

    begin
      # Décoder le token JWT pour obtenir l'utilisateur
      payload = JsonWebToken.decode(token)
      User.find_by(id: payload[:user_id])
    rescue JWT::VerificationError, JWT::ExpiredSignature => e
      Rails.logger.warn("Invalid JWT token: #{e.message}")
      nil
    end
  end

  def login_as(user)
    # Configurer la session avec un token valide
    token = JsonWebToken.encode(user_id: user.id)
    
    # Utiliser les helpers de test pour configurer la session
    # ou mocker plus agressivement
    allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:jwt_token).and_return(token)
    
    # Ou mocker complètement l'accès session
    allow_any_instance_of(ApplicationController).to receive(:session).and_return({jwt_token: token})
  end
end
