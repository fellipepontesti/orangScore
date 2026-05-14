require "securerandom"

module MercadoPago
  class CreatePixPreference
    def self.call(cobranca:, notification_url:, success_url:, failure_url:, pending_url:)
      new(
        cobranca: cobranca,
        notification_url: notification_url,
        success_url: success_url,
        failure_url: failure_url,
        pending_url: pending_url
      ).call
    end

    def initialize(cobranca:, notification_url:, success_url:, failure_url:, pending_url:, client: Client.new)
      @cobranca = cobranca
      @notification_url = notification_url
      @success_url = success_url
      @failure_url = failure_url
      @pending_url = pending_url
      @client = client
    end

    def call
      preference = client.create_preference(payload, idempotency_key: idempotency_key)

      cobranca.update!(
        gateway_cobranca_id: preference["id"],
        gateway_checkout_url: checkout_url(preference),
        gateway_status: "created"
      )

      preference
    end

    private

    attr_reader :cobranca, :notification_url, :success_url, :failure_url, :pending_url, :client

    def payload
      preference_payload = {
        items: [
          {
            title: "Plano #{cobranca.plano.capitalize} - OrangScore",
            quantity: 1,
            currency_id: "BRL",
            unit_price: cobranca.valor.to_f / 100
          }
        ],
        external_reference: cobranca.id.to_s,
        payment_methods: {
          default_payment_method_id: "pix",
          excluded_payment_types: [
            { id: "credit_card" },
            { id: "debit_card" },
            { id: "ticket" },
            { id: "atm" },
            { id: "prepaid_card" },
            { id: "digital_currency" },
            { id: "digital_wallet" }
          ],
          installments: 1
        },
        back_urls: {
          success: success_url,
          failure: failure_url,
          pending: pending_url
        },
        notification_url: notification_url
      }
    end

    def payer_email
      cobranca.user.email
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

    def idempotency_key
      "cobranca-#{cobranca.id}-preference-#{SecureRandom.uuid}"
    end

    def checkout_url(preference)
      return preference["init_point"] if Config.production?

      preference["sandbox_init_point"].presence || preference["init_point"]
    end
  end
end
