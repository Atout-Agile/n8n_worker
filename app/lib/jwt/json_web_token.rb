# frozen_string_literal: true

module JWT
  class JsonWebToken
    class << self
      def encode(payload)
        # Ajoute l'expiration au payload si elle n'est pas déjà définie
        payload = payload.dup
        payload[:exp] = expiration_from_now if payload[:exp].nil?
        
        JWT.encode(payload, secret_key)
      end

      def decode(token)
        # Retourne le payload décodé
        decoded = JWT.decode(token, secret_key)[0]
        HashWithIndifferentAccess.new(decoded)
      rescue JWT::DecodeError => e
        raise JWT::VerificationError, "Token invalide: #{e.message}"
      rescue JWT::ExpiredSignature
        raise JWT::ExpiredSignature, "Token expiré"
      end

      private

      def secret_key
        ENV.fetch('JWT_SECRET_KEY')
      end

      def expiration_from_now
        expiration = ENV.fetch('JWT_EXPIRATION', '24h')
        if expiration.end_with?('h')
          hours = expiration.to_i
          hours.hours.from_now.to_i
        else
          24.hours.from_now.to_i
        end
      end
    end
  end
end
