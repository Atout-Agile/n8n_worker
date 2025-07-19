# frozen_string_literal: true

# API controller for managing user API tokens via REST endpoints.
# Provides both web interface and JSON API for creating and viewing tokens.
# All actions require user authentication.
#
# @example POST /api/v1/tokens
#   curl -X POST "/api/v1/tokens" \
#        -H "Content-Type: application/json" \
#        -d '{"name": "Integration Token", "expires_at": "2025-12-31"}' \
#        -H "Authorization: Bearer <user_session_token>"
#
# @example GET /api/v1/tokens/:id
#   curl "/api/v1/tokens/123" \
#        -H "Authorization: Bearer <user_session_token>"
#
# @see ApiToken
# @see Mutations::CreateApiToken
# @since 2025-07-19
module Api
  module V1
    # Controller handling API token operations
    #
    # @!method show
    #   Displays a specific API token belonging to the current user
    #   @return [void] Renders the token details view
    #   @raise [ActiveRecord::RecordNotFound] If token doesn't exist or doesn't belong to user
    #
    # @!method create
    #   Creates a new API token or displays creation form
    #   For GET requests, displays the creation form
    #   For POST requests, creates a new token with provided parameters
    #   @return [void] Renders appropriate view with token data or form
    class TokensController < ApplicationController
      # Ensure user is authenticated for all actions
      before_action :authenticate_user!
      
      # Shows details of a specific API token
      #
      # @return [void] Renders the show view with @token instance variable
      # @raise [ActiveRecord::RecordNotFound] If token not found or unauthorized
      def show
        @token = current_user.api_tokens.find(params[:id])
      end

      # Handles both GET (form display) and POST (token creation) requests
      #
      # @return [void] Renders create view for GET or processes creation for POST
      # @note GET requests display the creation form
      # @note POST requests create new tokens and display results
      def create
        # If an ID is provided in parameters, we retrieve the existing token
        if params[:id].present?
          @token = current_user.api_tokens.find(params[:id])
          return render :show
        end

        # For GET requests without data, we just display the form
        if request.get?
          # If no parameter is provided, we prepare an empty token for the view
          @token = current_user.api_tokens.build unless @token
          return render :create
        end

        # For POST, we create a new token
        @token = current_user.api_tokens.build(token_params)
        
        # Generate the API token
        raw_token = SecureRandom.hex(32)
        @token.token_digest = Digest::SHA256.hexdigest(raw_token)
        @token.expires_at ||= 30.days.from_now

        if @token.save
          # Add the raw token for display (visible only at creation)
          @token.define_singleton_method(:raw_token) { raw_token }
          flash[:notice] = "API token created successfully"
        else
          flash[:alert] = "Error creating token: #{@token.errors.full_messages.join(', ')}"
        end
        
        render :create
      end

      private

      # Strong parameters for token creation
      #
      # @return [ActionController::Parameters] Permitted parameters
      # @api private
      def token_params
        params.permit(:name, :expires_at)
      end
    end
  end
end
