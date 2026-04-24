# frozen_string_literal: true

module Admin
  # Manages role–permission assignments via the admin interface.
  #
  # Provides a list of all roles and an edit page where an administrator
  # can toggle which permissions are assigned to a given role.
  # Deprecated permissions are exposed but cannot be selected.
  #
  # @example Routes
  #   GET  /admin/roles          → index
  #   GET  /admin/roles/:id/edit → edit
  #   PATCH /admin/roles/:id     → update
  #
  # @see Role
  # @see Permission
  # @since 2026-03-28
  class RolesController < BaseController
    before_action :set_role, only: [ :edit, :update ]

    # Lists all roles with their current permission count.
    #
    # @return [void]
    def index
      @roles = Role.includes(:permissions).order(:name)
    end

    # Shows the permission assignment form for a role.
    #
    # @return [void]
    def edit
      @permissions = Permission.order(:name)
    end

    # Updates the permissions assigned to a role.
    #
    # Only non-deprecated permissions submitted via the form are accepted;
    # any deprecated permission id is silently ignored.
    #
    # @return [void]
    def update
      permitted_ids = (params.dig(:role, :permission_ids) || [])
                      .map(&:to_i)
                      .select { |id| id > 0 }

      active_permission_ids = Permission.where(id: permitted_ids, deprecated: false).pluck(:id)

      @role.assign_permissions(active_permission_ids)
      redirect_to admin_roles_path, notice: "Permissions updated for role \"#{@role.name}\"."
    end

    private

    # @return [void]
    def set_role
      @role = Role.find(params[:id])
    end
  end
end
