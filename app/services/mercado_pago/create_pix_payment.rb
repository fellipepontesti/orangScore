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
      name_parts = (cobranca.user.name || "Usuario Orang").split(" ")
      first_name = name_parts.first
      last_name = name_parts.size > 1 ? name_parts.last : "Silva"

      {
        transaction_amount: (cobranca.valor.to_f / 100).round(2),
        description: "Plano #{cobranca.plano.capitalize} - OrangScore",
        payment_method_id: "pix",
        external_reference: cobranca.id.to_s,
        payer: {
          email: cobranca.user.email,
          first_name: first_name,
          last_name: last_name,
          identification: {
            type: "CPF",
            number: "19100000000" # CPF genérico para teste, o MP aceita qualquer um válido em sandbox/alguns casos prod se não for KYC restrito
          }
        },
        notification_url: notification_url
      }
    end

    def payer_email
      cobranca.user.email
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