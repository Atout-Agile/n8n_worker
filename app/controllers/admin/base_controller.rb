# frozen_string_literal: true

module Admin
  # Base controller for all admin-namespaced controllers.
  # Enforces that the current user exists and has the "admin" role.
  #
  # @example Inheriting from BaseController
  #   class Admin::RolesController < Admin::BaseController
  #     def index; end
  #   end
  #
  # @since 2026-03-28
  class BaseController < ApplicationController
    before_action :authenticate_admin!
  end
end
