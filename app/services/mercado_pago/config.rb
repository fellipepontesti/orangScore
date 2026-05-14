module MercadoPago
  class ConfigurationError < StandardError
    def user_message
      message
    end
  end

  class Config
    def self.access_token
      env_value(access_token_key)
    end

    def self.webhook_secret
      env_value(webhook_secret_key)
    end

    def self.test_payer_email
      return if production?

      env_value("MERCADO_PAGO_TEST_PAYER_EMAIL") || "test_user_br@testuser.com"
    end

    def self.access_token_key
      production? ? "MERCADO_PAGO_PRODUCTION_ACCESS_TOKEN" : "MERCADO_PAGO_TEST_ACCESS_TOKEN"
    end

    def self.webhook_secret_key
      production? ? "MERCADO_PAGO_PRODUCTION_WEBHOOK_SECRET" : "MERCADO_PAGO_TEST_WEBHOOK_SECRET"
    end

    def self.production?
      Rails.env.production?
    end

    def self.env_value(key)
      ENV[key].to_s.strip.presence
    end
  end
end
