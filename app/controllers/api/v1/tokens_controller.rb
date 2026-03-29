# frozen_string_literal: true

# Controller for managing API tokens via the web interface.
# All actions require user authentication.
#
# @see ApiToken
# @see Mutations::CreateApiToken
# @since 2025-07-19
module Api
  module V1
    class TokensController < ApplicationController
      before_action :authenticate_user!
      before_action :set_token, only: [:show, :revoke, :renew, :destroy]

      # Lists all tokens for the current user.
      # Redirects to new token form if the user has no tokens yet.
      #
      # @return [void]
      def index
        @tokens = current_user.api_tokens.order(created_at: :desc)
        redirect_to new_api_v1_token_path if @tokens.empty?
      end

      # Displays a specific token.
      #
      # @return [void]
      def show
      end

      # Displays the new token form.
      #
      # @return [void]
      def new
        @token = current_user.api_tokens.build
        @role_permissions = current_user.assignable_permissions.order(:name)
      end

      # Creates a new API token.
      #
      # Assigns only permissions that belong to the current user's role and are
      # not deprecated. Any out-of-scope permission id is silently ignored before
      # the model-level validation runs.
      #
      # @return [void]
      def create
        @token = current_user.api_tokens.build(token_params)
        raw_token = SecureRandom.hex(32)
        @token.token_digest = Digest::SHA256.hexdigest(raw_token)
        @token.expires_at ||= ApiToken::DEFAULT_EXPIRATION_DAYS.days.from_now

        allowed_ids = current_user.assignable_permissions.pluck(:id).to_set
        selected_ids = (params.dig(:token, :permission_ids) || []).map(&:to_i).select { |id| allowed_ids.include?(id) }
        @token.permission_ids = selected_ids

        if @token.save
          flash[:raw_token] = raw_token
          redirect_to api_v1_token_path(@token), notice: "API token created successfully"
        else
          @role_permissions = current_user.assignable_permissions.order(:name)
          render :new, status: :unprocessable_entity
        end
      end

      # Revokes a token by setting its expiration to now.
      #
      # @return [void]
      # @note The token record is kept for audit purposes
      def revoke
        @token.update!(expires_at: Time.current)
        redirect_to api_v1_tokens_path, notice: "Token \"#{@token.name}\" has been revoked."
      end

      # Renews a token by extending its expiration by 30 days from now.
      #
      # @return [void]
      def renew
        @token.update!(expires_at: ApiToken::DEFAULT_EXPIRATION_DAYS.days.from_now)
        redirect_to api_v1_tokens_path, notice: "Token \"#{@token.name}\" renewed until #{@token.expires_at.strftime('%b %d, %Y')}."
      end

      # Permanently deletes a token.
      #
      # @return [void]
      def destroy
        name = @token.name
        @token.destroy!
        redirect_to api_v1_tokens_path, notice: "Token \"#{name}\" has been deleted."
      end

      private

      # @api private
      def set_token
        @token = current_user.api_tokens.find(params[:id])
      end

      # @api private
      def token_params
        params.permit(:name, :expires_at)
      end
    end
  end
end
