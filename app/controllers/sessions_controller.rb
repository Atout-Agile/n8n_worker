class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if current_user
  end

  def create
    # Execute the GraphQL login mutation
    result = N8nWorkerSchema.execute(
      login_mutation,
      variables: {
        email: params[:email],
        password: params[:password]
      }
    ).to_h

    if result.dig("data", "login", "token")
      # Store token in session
      session[:jwt_token] = result["data"]["login"]["token"]

      # Store in localStorage via JavaScript
      @token = result["data"]["login"]["token"]

      # Redirect to dashboard
      redirect_to dashboard_path
    else
      # Get errors
      errors = result.dig("data", "login", "errors") || []
      errors = result["errors"].map { |e| e["message"] } if errors.empty? && result["errors"]

      flash.now[:alert] = errors.join(", ").presence || "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def login_mutation
    <<~GRAPHQL
      mutation Login($email: String!, $password: String!) {
        login(email: $email, password: $password) {
          token
          user {
            id
            email
            username
          }
          errors
        }
      }
    GRAPHQL
  end
end
