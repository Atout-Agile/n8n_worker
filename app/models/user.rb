# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :role
  has_many :api_tokens, dependent: :destroy
  has_one :assistant_config, class_name: "UserAssistantConfig", dependent: :destroy
  has_many :notification_channels, dependent: :destroy
  has_many :calendar_events, dependent: :destroy
  has_many :alert_emissions, dependent: :destroy

  has_secure_password

  # Returns the non-deprecated permissions available to this user via their role.
  # Used to scope token permission selection and validate token assignments.
  #
  # @return [ActiveRecord::Relation<Permission>]
  def assignable_permissions
    role.permissions.reject(&:deprecated)
  end

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8 }, on: :create
end
