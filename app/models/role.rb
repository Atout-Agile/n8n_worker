# frozen_string_literal: true

class Role < ApplicationRecord
  # Associations
  has_many :users, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
end
