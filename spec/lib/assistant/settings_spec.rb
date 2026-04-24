# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assistant::Settings do
  describe '.current' do
    it 'returns the global frozen instance' do
      expect(Assistant::Settings.current).to be_frozen
    end

    it 'exposes default_sync_interval_seconds' do
      expect(Assistant::Settings.current.sync_interval_seconds).to eq 120
    end

    it 'exposes default disappearance_grace_ticks' do
      expect(Assistant::Settings.current.disappearance_grace_ticks).to eq 3
    end

    it 'exposes default planning_horizon_days' do
      expect(Assistant::Settings.current.planning_horizon_days).to eq 30
    end

    it 'exposes default retry_grace_seconds' do
      expect(Assistant::Settings.current.retry_grace_seconds).to eq 120
    end

    it 'exposes default_reminder_intervals' do
      expect(Assistant::Settings.current.default_reminder_intervals).to eq [ 60, 15, 5 ]
    end
  end

  describe '.build_from' do
    it 'uses provided values when given' do
      settings = Assistant::Settings.build_from(
        sync_interval_seconds: 300,
        disappearance_grace_ticks: 5,
        planning_horizon_days: 60,
        retry_grace_seconds: 180,
        default_reminder_intervals: [ 120, 30, 10 ]
      )
      expect(settings.sync_interval_seconds).to eq 300
      expect(settings.disappearance_grace_ticks).to eq 5
      expect(settings.planning_horizon_days).to eq 60
      expect(settings.retry_grace_seconds).to eq 180
      expect(settings.default_reminder_intervals).to eq [ 120, 30, 10 ]
      expect(settings).to be_frozen
    end

    it 'rejects non-positive sync_interval_seconds' do
      expect { Assistant::Settings.build_from(sync_interval_seconds: 0) }.to raise_error(ArgumentError)
    end

    it 'rejects a negative retry_grace_seconds' do
      expect { Assistant::Settings.build_from(retry_grace_seconds: -1) }.to raise_error(ArgumentError)
    end
  end
end
