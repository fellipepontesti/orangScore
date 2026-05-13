module Pagamentos
  class Create
    def initialize(cobranca:, session:)
      @cobranca = cobranca
      @session = session
    end

    def call
      Pagamento.create!(
        user: @cobranca.user,
        valor: @session.amount_total,
        status: :pago,
        stripe_payment_intent_id: @session.payment_intent,
        plano: @cobranca.plano,
        pago_em: Time.current,
        metadata: @session.to_h
      )
    end
  end
end