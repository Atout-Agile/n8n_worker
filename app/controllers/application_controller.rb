class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_user
  
  def current_user
    @current_user ||= begin
      token = session[:jwt_token]
      return nil unless token
      
      # Use the existing User query to get the user
      result = N8nWorkerSchema.execute(
        user_query,
        variables: {
          id: decode_token(token)[:user_id]
        }
      ).to_h
      
      if result.dig("data", "user")
        # Convert GraphQL data to User object
        user_data = result["data"]["user"]
        User.find_by(id: user_data["id"])
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching current user: #{e.message}")
      nil
    end
  end
  
  def authenticate_user!
    redirect_to login_path, alert: "Please log in to access this page." unless current_user
  end
  
  private
  
  def decode_token(token)
    JsonWebToken.decode(token)
  end
  
  def user_query
    <<~GRAPHQL
      query User($id: ID!) {
        user(id: $id) {
          id
          email
          username
          role {
            name
          }
        }
      }
    GRAPHQL
  end
end
