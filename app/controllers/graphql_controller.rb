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

    auth = authenticate_from_header
    context = {
      current_user: auth[:user] || current_user,
      current_token: auth[:token],
      operation_name: operation_name
    }

    if auth[:token]
      Rails.logger.info(JSON.generate(
        event: "graphql.token_access",
        token_id: auth[:token].id,
        user_id: auth[:user].id,
        operation: operation_name
      ))
    end

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

  # Resolves the authenticated user and API token from the Authorization header.
  # Tries API token lookup first, then falls back to JWT.
  #
  # @return [Hash] with keys :user [User, nil] and :token [ApiToken, nil]
  # @note Accepts "Authorization: Bearer <token>" header
  # @note :token is only set when authentication was via API token (not JWT)
  def authenticate_from_header
    auth_header = request.headers['Authorization']
    return { user: nil, token: nil } unless auth_header&.start_with?('Bearer ')

    raw_token = auth_header.split(' ', 2)[1]
    return { user: nil, token: nil } if raw_token.blank?

    # Try API token first (raw hex stored as SHA256 digest)
    api_token = ApiToken.find_by_token(raw_token)
    if api_token&.active?
      api_token.touch_last_used!
      return { user: api_token.user, token: api_token }
    end

    # Fall back to JWT
    begin
      payload = JsonWebToken.decode(raw_token)
      { user: User.find_by(id: payload[:user_id]), token: nil }
    rescue JWT::VerificationError, JWT::ExpiredSignature => e
      Rails.logger.warn("Invalid JWT token: #{e.message}")
      { user: nil, token: nil }
    end
  end
end
