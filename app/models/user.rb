# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :role
  has_many :api_tokens, dependent: :destroy

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8 }, on: :create
end
