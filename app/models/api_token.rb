# frozen_string_literal: true

class ApiToken < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :token_digest, presence: true
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where('expires_at > ?', Time.current) }
end
