# frozen_string_literal: true

# Base policy providing shared authorization context and permission helpers.
#
# The authorization context receives :user (current user) and :token (API token
# when authenticated via API token, nil for JWT auth).
#
# Permission resolution:
# - API token auth  → use the token's own permissions (subset of role)
# - JWT auth         → use the user's role permissions
# - Unauthenticated → empty set (all checks fail)
#
# @example Checking a permission in a subclass
#   def read?
#     permission?("users:read")
#   end
#
# @see UserPolicy
# @see ApiTokenPolicy
# @since 2026-03-28
class ApplicationPolicy < ActionPolicy::Base
  # @!attribute [r] user
  #   @return [User, nil] The authenticated user
  authorize :user, optional: true

  # @!attribute [r] token
  #   @return [ApiToken, nil] The API token used for auth, or nil for JWT auth
  authorize :token, optional: true

  # Returns the set of active permission names for the current request.
  # Uses token-level permissions when authenticated via API token,
  # falls back to the user's role permissions for JWT auth.
  #
  # @return [Set<String>] Active permission names (e.g. #<Set: {"users:read"}>)
  # @api private
  def active_permissions
    @active_permissions ||= begin
      perms = if token&.active?
        token.permissions
      else
        user&.role&.permissions || Permission.none
      end
      perms.pluck(:name).to_set
    end
  end

  private

  # @param name [String] permission name, e.g. "users:read"
  # @return [Boolean] true if current context includes this permission
  # @api private
  def permission?(name)
    user.present? && active_permissions.include?(name)
  end
end
