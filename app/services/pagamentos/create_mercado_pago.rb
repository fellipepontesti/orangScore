require "bigdecimal"

module Pagamentos
  class CreateMercadoPago
    def initialize(cobranca:, payment:)
      @cobranca = cobranca
      @payment = payment
    end

    def call
      Pagamento.find_or_create_by!(mercado_pago_payment_id: payment["id"].to_s) do |pagamento|
        pagamento.user = cobranca.user
        pagamento.cobranca = cobranca
        pagamento.valor = valor
        pagamento.status = :pago
        pagamento.plano = cobranca.plano
        pagamento.pago_em = pago_em
        pagamento.metadata = payment
      end
    end

    private

    attr_reader :cobranca, :payment

    def valor
      (BigDecimal(payment["transaction_amount"].to_s) * 100).to_i
    end

    def pago_em
      Time.zone.parse(payment["date_approved"].to_s) || Time.current
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
