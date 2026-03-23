# frozen_string_literal: true

# API Token model for managing user authentication tokens.
# Provides secure token generation, validation, and lifecycle management.
# Tokens are stored as SHA256 digests for security.
#
# @example Creating a token for a user
#   token = ApiToken.generate_for_user(user, "Integration Token", expires_in_days: 7)
#   puts token.raw_token if token.persisted?
#
# @example Finding a token by raw value
#   found_token = ApiToken.find_by_token("abc123def456...")
#   found_token&.touch_last_used!
#
# @example Checking token status
#   token.active?     # => true/false
#   token.expired?    # => true/false
#   token.expires_in_words  # => "in 5 days"
#
# @see Mutations::CreateApiToken
# @see Api::V1::TokensController
# @since 2025-07-19
class ApiToken < ApplicationRecord
  include ActionView::Helpers::DateHelper
  
  # @!attribute [r] id
  #   @return [Integer] Primary key
  # @!attribute [rw] name  
  #   @return [String] Descriptive name for the token
  # @!attribute [rw] token_digest
  #   @return [String] SHA256 digest of the raw token
  # @!attribute [rw] expires_at
  #   @return [DateTime] When the token expires
  # @!attribute [rw] last_used_at
  #   @return [DateTime, nil] When the token was last used
  # @!attribute [r] created_at
  #   @return [DateTime] When the token was created
  # @!attribute [r] updated_at
  #   @return [DateTime] When the token was last updated
  # @!attribute [rw] user_id
  #   @return [Integer] Foreign key to the user who owns this token

  # Associations
  
  # @!attribute [r] user
  #   @return [User] The user who owns this token
  belongs_to :user

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id, message: "You already have a token with this name" }
  validates :token_digest, presence: true
  validates :expires_at, presence: true

  # Scopes
  
  # @!scope class
  # @return [ActiveRecord::Relation<ApiToken>] Tokens that have not yet expired
  scope :active, -> { where('expires_at > ?', Time.current) }

  # Callbacks
  before_validation :set_default_expiration, if: -> { expires_at.blank? }

  class << self
    # Generates a new API token for a user with secure random generation
    #
    # @param user [User] The user to create the token for
    # @param name [String] Descriptive name for the token
    # @param expires_in_days [Integer] Number of days until expiration (default: 30)
    # @return [ApiToken] The created token with a raw_token method if successful
    # @example
    #   token = ApiToken.generate_for_user(user, "My App Token", expires_in_days: 60)
    #   puts token.raw_token if token.persisted?
    def generate_for_user(user, name, expires_in_days: 30)
      raw_token = SecureRandom.hex(32)
      
      api_token = new(
        user: user,
        name: name,
        token_digest: Digest::SHA256.hexdigest(raw_token),
        expires_at: expires_in_days.days.from_now
      )
      
      if api_token.save
        # Add the raw token to the object for return
        api_token.define_singleton_method(:raw_token) { raw_token }
        api_token
      else
        api_token
      end
    end

    # Finds a token by its raw value (securely using digest comparison)
    #
    # @param raw_token [String] The original token string
    # @return [ApiToken, nil] The matching token or nil if not found
    # @example
    #   token = ApiToken.find_by_token("abc123def456...")
    #   token&.touch_last_used!
    def find_by_token(raw_token)
      token_digest = Digest::SHA256.hexdigest(raw_token)
      find_by(token_digest: token_digest)
    end
  end

  # Instance methods

  # Checks if the token is still active (not expired)
  #
  # @return [Boolean] true if token has not expired, false otherwise
  def active?
    expires_at > Time.current
  end

  # Checks if the token has expired
  #
  # @return [Boolean] true if token has expired, false otherwise
  def expired?
    !active?
  end

  # Updates the last_used_at timestamp without triggering callbacks
  #
  # @return [Boolean] true if update was successful
  # @note Uses update_column for performance (skips validations and callbacks)
  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  # Returns human-readable time until expiration
  #
  # @return [String] Human-friendly expiration description
  # @example
  #   token.expires_in_words  # => "in 3 days"
  #   expired_token.expires_in_words  # => "Expired"
  def expires_in_words
    return "Expired" if expired?
    
    distance_of_time_in_words(Time.current, expires_at)
  end

  private

  # Sets default expiration to 30 days from now if not specified
  #
  # @return [void]
  # @api private
  def set_default_expiration
    self.expires_at = 30.days.from_now
  end
end
