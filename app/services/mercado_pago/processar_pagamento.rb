module MercadoPago
  class ProcessarPagamento
    APPROVED_STATUS = "approved".freeze

    def initialize(payment:, cobranca: nil)
      @payment = payment
      @cobranca = cobranca || find_cobranca
    end

    def call
      return unless cobranca

      cobranca.update!(gateway_status: payment["status"])
      return unless payment["status"] == APPROVED_STATUS
      return if cobranca.pago?

      ActiveRecord::Base.transaction do
        cobranca.update!(
          status: :pago,
          paid_at: paid_at
        )

        Pagamentos::CreateMercadoPago.new(cobranca: cobranca, payment: payment).call
        Assinaturas::Ativar.new(usuario: cobranca.user, plano: cobranca.plano).call
      end
    end

    private

    attr_reader :payment, :cobranca

    def find_cobranca
      Cobranca.find_by(gateway: :mercado_pago, gateway_cobranca_id: payment["id"].to_s) ||
        Cobranca.find_by(gateway: :mercado_pago, id: payment["external_reference"])
    end

    def paid_at
      Time.zone.parse(payment["date_approved"].to_s) || Time.current
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
