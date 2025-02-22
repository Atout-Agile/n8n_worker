# frozen_string_literal: true

module Api
  module V1
    class TokensController < ApplicationController
      def create
        @token = ApiToken.find(params[:id])
      end
    end
  end
end
