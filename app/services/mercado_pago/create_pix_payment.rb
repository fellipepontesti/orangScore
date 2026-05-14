module MercadoPago
  class CreatePixPayment
    def self.call(cobranca:, notification_url:)
      new(
        cobranca: cobranca,
        notification_url: notification_url
      ).call
    end

    def initialize(cobranca:, notification_url:, client: Client.new)
      @cobranca = cobranca
      @notification_url = notification_url
      @client = client
    end

    def call
      payment = client.create_payment(
        payload,
        idempotency_key: idempotency_key
      )

      save_payment!(payment)

      payment
    end

    private

    attr_reader :cobranca, :notification_url, :client

    def payload
      {
        transaction_amount: (cobranca.valor.to_f / 100).round(2),
        description: "Pagamento de teste OrangScore",
        payment_method_id: "pix",
        external_reference: cobranca.id.to_s,
        payer: {
          email: payer_email,
          identification: {
            type: "CPF",
            number: "19100000000"
          }
        },
        notification_url: "https://#{ENV['WEBHOOK_HOST']}/mercado_pago/webhook"
      }
    end

    def payer_email
      # Tente usar o e-mail que aparece no painel do Mercado Pago para o usuário TESTUSER4478077780224338783
      # Se não souber, esse padrão abaixo costuma funcionar se o usuário foi criado agora.
      "test_user_447807778@testuser.com"
    end

    def idempotency_key
      "cobranca-#{cobranca.id}-pix-#{SecureRandom.uuid}"
    end

    def save_payment!(payment)
      cobranca.update!(
        gateway_cobranca_id: payment["id"].to_s,
        gateway_status: payment["status"],

        pix_qr_code: payment.dig(
          "point_of_interaction",
          "transaction_data",
          "qr_code"
        ),

        pix_qr_code_base64: payment.dig(
          "point_of_interaction",
          "transaction_data",
          "qr_code_base64"
        )
      )
    end
  end
end