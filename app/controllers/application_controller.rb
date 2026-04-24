class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user

  def current_user
    @current_user ||= begin
      token = session[:jwt_token]
      return nil unless token

      payload = decode_token(token)
      User.includes(role: :permissions).find_by(id: payload[:user_id])
    rescue StandardError => e
      Rails.logger.error("Error fetching current user: #{e.message}")
      nil
    end
  end

  def authenticate_user!
    redirect_to login_path, alert: "Please log in to access this page." unless current_user
  end

  def authenticate_admin!
    authenticate_user!
    return if performed?

    redirect_to dashboard_path, alert: "Access denied." unless current_user.role.name == "admin"
  end

  private

  def decode_token(token)
    JsonWebToken.decode(token)
  end
end
