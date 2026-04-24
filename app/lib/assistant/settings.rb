# frozen_string_literal: true

module Assistant
  # System-wide settings for the assistant subsystem. Loaded once at
  # boot and frozen. See spec §4.2 for the functional definitions.
  #
  # @example Reading a setting
  #   Assistant::Settings.current.sync_interval_seconds
  #
  # @see config/initializers/assistant_settings.rb
  # @since 2026-04-11
  class Settings
    DEFAULTS = {
      sync_interval_seconds: 120,
      disappearance_grace_ticks: 3,
      planning_horizon_days: 30,
      retry_grace_seconds: 120,
      default_reminder_intervals: [ 60, 15, 5 ]
    }.freeze

    attr_reader :sync_interval_seconds,
                :disappearance_grace_ticks,
                :planning_horizon_days,
                :retry_grace_seconds,
                :default_reminder_intervals

    # @return [Assistant::Settings] the frozen global instance
    def self.current
      @current ||= build_from({})
    end

    # Rebuilds the global instance. Intended to be called once from an
    # initializer.
    #
    # @param attributes [Hash]
    # @return [Assistant::Settings]
    def self.configure(attributes)
      @current = build_from(attributes)
    end

    # @param attributes [Hash]
    # @return [Assistant::Settings]
    # @raise [ArgumentError] when a value is out of range
    def self.build_from(attributes)
      values = DEFAULTS.merge(attributes.to_h.compact.transform_keys(&:to_sym))
      new(values).freeze
    end

    def initialize(values)
      @sync_interval_seconds = Integer(values.fetch(:sync_interval_seconds))
      @disappearance_grace_ticks = Integer(values.fetch(:disappearance_grace_ticks))
      @planning_horizon_days = Integer(values.fetch(:planning_horizon_days))
      @retry_grace_seconds = Integer(values.fetch(:retry_grace_seconds))
      @default_reminder_intervals = Array(values.fetch(:default_reminder_intervals)).map(&:to_i)
      validate!
    end

    private

    def validate!
      raise ArgumentError, "sync_interval_seconds must be positive" unless @sync_interval_seconds.positive?
      raise ArgumentError, "disappearance_grace_ticks must be positive" unless @disappearance_grace_ticks.positive?
      raise ArgumentError, "planning_horizon_days must be positive" unless @planning_horizon_days.positive?
      raise ArgumentError, "retry_grace_seconds must be >= 0" if @retry_grace_seconds.negative?
      return unless @default_reminder_intervals.any?(&:negative?)

      raise ArgumentError, "default_reminder_intervals must contain non-negative integers"
    end
  end
end
