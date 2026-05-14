require "securerandom"

module MercadoPago
  class CreatePixPayment
    def self.call(cobranca:, notification_url:)
      new(cobranca: cobranca, notification_url: notification_url).call
    end

    def initialize(cobranca:, notification_url:, client: Client.new)
      @cobranca = cobranca
      @notification_url = notification_url
      @client = client
    end

    def call
      payment = client.create_payment(payload, idempotency_key: idempotency_key)
      transaction_data = payment.dig("point_of_interaction", "transaction_data") || {}

      cobranca.update!(
        gateway_cobranca_id: payment["id"],
        gateway_checkout_url: transaction_data["ticket_url"],
        gateway_status: payment["status"],
        pix_qr_code: transaction_data["qr_code"],
        pix_qr_code_base64: transaction_data["qr_code_base64"]
      )

      payment
    end

    private

    attr_reader :cobranca, :notification_url, :client

    def payload
      payment_payload = {
        transaction_amount: cobranca.valor.to_f / 100,
        description: "Plano #{cobranca.plano.capitalize} - OrangScore",
        payment_method_id: "pix",
        payer: {
          email: payer_email
        },
        external_reference: cobranca.id.to_s,
        date_of_expiration: cobranca.expires_at.iso8601(3)
      }

      payment_payload[:notification_url] = notification_url if valid_notification_url?
      payment_payload
    end

    def idempotency_key
      "cobranca-#{cobranca.id}-#{SecureRandom.uuid}"
    end

    def payer_email
      return cobranca.user.email if Config.production?
      return Config.test_payer_email if Config.test_payer_email.present?

      "test@testuser.com"
    end

    def valid_notification_url?
      uri = URI.parse(notification_url.to_s)

      uri.is_a?(URI::HTTP) &&
        uri.host.present? &&
        uri.host.exclude?("localhost") &&
        uri.host != "127.0.0.1"
    rescue URI::InvalidURIError
      false
    end
  end
end
