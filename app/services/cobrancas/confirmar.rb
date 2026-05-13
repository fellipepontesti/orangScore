module Cobrancas
  class Confirmar
    def initialize(cobranca:, session:)
      @cobranca = cobranca
      @session = session
    end

    def call
      @cobranca.update!(
        status: :paga,
        stripe_payment_intent_id: @session.payment_intent,
        pago_em: Time.current
      )
    end
  end
end