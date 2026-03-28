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

