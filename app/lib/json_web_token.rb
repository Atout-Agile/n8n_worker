# frozen_string_literal: true

class JsonWebToken
  class << self
    def encode(payload)
      # Ajouter l'expiration si elle n'est pas déjà définie
      expiration = ENV.fetch('JWT_EXPIRATION', '24h')
      payload[:exp] ||= expiration_from_string(expiration)

      ::JWT.encode(payload, secret_key)
    end

    def decode(token)
      decoded = ::JWT.decode(token, secret_key)[0]
      HashWithIndifferentAccess.new(decoded)
    rescue ::JWT::DecodeError => e
      raise ::JWT::VerificationError, e.message
    end

    private

    def secret_key
      ENV.fetch('JWT_SECRET_KEY') do
        Rails.application.credentials.secret_key_base
      end
    end

    def expiration_from_string(expiration)
      if expiration =~ /(\d+)h/
        $1.to_i.hours.from_now.to_i
      else
        24.hours.from_now.to_i
      end
    end
  end
end
