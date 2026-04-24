# frozen_string_literal: true

class N8nWorkerSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Return a structured NOT_AUTHORIZED error when Action Policy denies access.
  # Also emits a structured warning log with denial context.
  rescue_from ActionPolicy::Unauthorized do |error, _obj, _args, ctx, _field|
    Rails.logger.warn(JSON.generate(
      event: "graphql.access_denied",
      user_id: ctx[:current_user]&.id,
      token_id: ctx[:current_token]&.id,
      operation: ctx[:operation_name],
      rule: error.rule
    ))
    raise GraphQL::ExecutionError.new(
      "NOT_AUTHORIZED",
      extensions: { code: "UNAUTHORIZED" }
    )
  end

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  # Maps a Ruby model instance to its corresponding GraphQL type.
  # Called by graphql-ruby when resolving abstract types (Union/Interface),
  # e.g. when using the Relay +node+ or +nodes+ queries.
  def self.resolve_type(abstract_type, obj, ctx)
    case obj
    when User                       then Types::UserType
    when ApiToken                   then Types::ApiTokenType
    when Role                       then Types::RoleType
    when Permission                 then Types::PermissionType
    when UserAssistantConfig        then Types::UserAssistantConfigType
    when NotificationChannel        then Types::NotificationChannelType
    when SharedNotificationChannel  then Types::SharedNotificationChannelType
    when CalendarEvent              then Types::CalendarEventType
    when CalendarReminder           then Types::CalendarReminderType
    when AlertEmission              then Types::AlertEmissionType
    else
      raise GraphQL::RequiredImplementationMissingError, "No GraphQL type registered for #{obj.class.name}"
    end
  end

  # Limit the size of incoming queries:
  max_query_string_tokens(5000)

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
