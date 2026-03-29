# Issue Labels

## Types
- `type:feature` : New feature
- `type:test` : Integration or system test
- `type:documentation` : Documentation

## Domains
- `domain:graphql` : GraphQL API
- `domain:auth` : Authentication
- `domain:ui` : User interface

## Priority
- `priority:high` : Critical for functionality
- `priority:medium` : Important but not blocking
- `priority:low` : Nice to have

## Status
- `status:ready` : Ready to be developed
- `status:blocked` : Blocked by another issue

---

# Documentation Standards

## YARD Documentation

This project uses YARD for generating Ruby API documentation. The documentation is automatically generated and served using rake tasks (see README.md).

### Quick Start
```bash
# Generate all documentation
rake docs:generate

# Serve documentation locally
rake docs:serve
```

Access documentation at:
- Ruby/Rails API: http://localhost:8808
- GraphQL API: http://localhost:8809

### Documentation Requirements

All public classes, modules, and methods **must** include YARD documentation when:
- Adding new features
- Modifying existing public APIs
- Creating GraphQL mutations or types
- Adding controller actions
- Creating or updating models

### YARD Standards

#### Classes and Modules
```ruby
# Brief description of the class purpose.
# More detailed explanation if needed, including usage patterns.
#
# @example Basic usage
#   MyClass.new.do_something
#
# @see RelatedClass
# @since 2025-01-19
class MyClass
end
```

#### Methods
```ruby
# Brief description of what the method does.
#
# @param name [String] Description of the parameter
# @param options [Hash] Optional parameters
# @option options [Integer] :limit (10) Maximum number of results
# @return [Array<String>] Description of return value
# @raise [ArgumentError] When invalid parameters provided
# @example
#   my_method("test", limit: 5)
def my_method(name, options = {})
end
```

#### GraphQL Components
```ruby
# GraphQL mutation for creating resources.
# Detailed explanation of the mutation's purpose and behavior.
#
# @example GraphQL usage
#   mutation {
#     createResource(name: "example") {
#       resource { id name }
#       errors
#     }
#   }
#
# @see Types::ResourceType
class CreateResource < GraphQL::Schema::Mutation
  # @!attribute [r] name
  #   @return [String] Resource name
  argument :name, String, required: true, description: "Resource name"
  
  # @!attribute [r] resource
  #   @return [Types::ResourceType, nil] Created resource
  field :resource, Types::ResourceType, null: true
end
```

### Required Tags

- `@param` for all parameters
- `@return` for return values
- `@example` for complex methods
- `@see` for cross-references
- `@since` for new features (with date)
- `@raise` for expected exceptions
- `@note` for important information
- `@api private` for internal methods

### Cross-References

Always link related components:
```ruby
# @see Models::User
# @see Controllers::UsersController  
# @see Types::UserType
```

### Security Notes

For authentication/authorization code:
```ruby
# @note Requires user authentication
# @note Token is only visible during creation for security
```

### Validation

Before submitting PR:
1. Run `rake docs:generate` to ensure no YARD warnings
2. Check generated documentation for completeness
3. Verify examples are accurate and working

---

# Permission System

## Overview

GraphQL operations are protected by a permission-based authorization system built on [Action Policy](https://actionpolicy.evilmartians.io/). Permissions follow the format `resource:action` (e.g. `users:read`).

Two auth modes are supported:

| Auth mode | Permissions source |
|---|---|
| JWT (web session) | User's role permissions |
| API token | Token's own permissions (subset of role) |

## Available Permissions

| Permission | GraphQL operation(s) |
|---|---|
| `users:read` | `query { user }`, `query { users }` |
| `users:write` | `mutation { updateUser }` |
| `tokens:read` | `query { apiTokens }`, `query { verifyToken }` |
| `tokens:write` | `mutation { createApiToken }`, `mutation { revokeApiToken }`, `mutation { updateApiTokenPermissions }` |
| `roles:read` | `query { roles }`, `query { permissions }` |
| `roles:write` | `mutation { updateRolePermissions }` |
| _(none)_ | `mutation { login }` — public |

## Adding a New Permission

When you add a new protected query or mutation:

1. **Declare the permission** on the resolver class:
   ```ruby
   class Queries::Jobs < BaseQuery
     permission_required "jobs:read"
     # ...
   end
   ```

2. **Create the policy rule** in the relevant policy class (e.g. `app/policies/job_policy.rb`):
   ```ruby
   class JobPolicy < ApplicationPolicy
     def read? = permission?("jobs:read")
   end
   ```

3. **Authorize in the resolver** using Action Policy:
   ```ruby
   def resolve
     authorize! current_user, to: :read?, with: JobPolicy
     # ...
   end
   ```

4. **Sync the database** so the new permission appears in the admin UI:
   ```bash
   rails permissions:sync
   ```
   This scans all resolvers for `permission_required` declarations and upserts `Permission` records. It is idempotent — safe to run multiple times.

5. **Assign the permission to roles** via the admin interface at `/admin/roles`, via the `updateRolePermissions` GraphQL mutation, or programmatically:
   ```ruby
   Permission.find_by!(name: "jobs:read").tap { |p| Role.find_by!(name: "admin").permissions << p }
   ```

## `permission_required` DSL

`BaseMutation` and `BaseQuery` both expose a `permission_required` class method used as a metadata annotation. It is scanned by `Permissions::SyncService` and used to populate the `permissions` table.

```ruby
class Mutations::CreateJob < BaseMutation
  permission_required "jobs:write"
end
```

The `Login` mutation intentionally does **not** declare `permission_required` — it is public.

## Error Format

When a protected operation is called without the required permission, the API returns:

```json
{
  "errors": [{
    "message": "NOT_AUTHORIZED",
    "extensions": { "code": "UNAUTHORIZED" }
  }]
}
```

## Logging

Every API token request and every access denial emits a structured JSON log entry:

- `graphql.token_access` (info): authorized token requests
- `graphql.access_denied` (warn): denied requests with `user_id`, `token_id`, `operation`, and `rule`

