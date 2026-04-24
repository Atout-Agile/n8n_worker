# frozen_string_literal: true

module Assistant
  module Channels
    # Maps a NotificationChannel record to a concrete adapter instance.
    # For shared channels, the adapter is chosen based on the underlying
    # shared channel's type; a decorator exposes the shared config while
    # keeping the personal channel's ownership identity.
    #
    # @since 2026-04-11
    module Registry
      TYPE_TO_ADAPTER = {
        "internal" => InternalAdapter,
        "ntfy" => NtfyAdapter,
        "email" => EmailAdapter,
        "webhook" => WebhookAdapter
      }.freeze

      # @param channel [NotificationChannel]
      # @return [BaseAdapter]
      # @raise [ArgumentError]
      def self.adapter_for(channel)
        type = resolve_type(channel)
        adapter_class = TYPE_TO_ADAPTER.fetch(type) do
          raise ArgumentError, "no adapter for channel type #{type.inspect}"
        end
        adapter_class.new(channel: effective_channel(channel))
      end

      private_class_method def self.resolve_type(channel)
        channel.channel_type == "shared" ? channel.shared_notification_channel.channel_type : channel.channel_type
      end

      private_class_method def self.effective_channel(channel)
        return channel unless channel.channel_type == "shared"

        SharedChannelDecorator.new(channel)
      end

      # Decorates a shared NotificationChannel so its adapter sees the
      # shared channel's config while retaining the per-user identity.
      #
      # @api private
      class SharedChannelDecorator
        def initialize(personal_channel)
          @personal_channel = personal_channel
        end

        def user
          @personal_channel.user
        end

        def config
          @personal_channel.shared_notification_channel.config
        end

        def channel_type
          @personal_channel.shared_notification_channel.channel_type
        end

        def id
          @personal_channel.id
        end
      end
    end
  end
end
