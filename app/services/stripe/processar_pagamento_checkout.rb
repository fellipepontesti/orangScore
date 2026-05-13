module Stripe
  class ProcessarPagamentoCheckout
    def initialize(session:)
      @session = session
    end

    def call
      cobranca = Cobranca.find(@session.metadata.cobranca_id)

      return if cobranca.paga?

      ActiveRecord::Base.transaction do
        Cobrancas::Confirmar.new(cobranca: cobranca, session: @session).call
        Pagamentos::Create.new(cobranca: cobranca, session: @session).call
        Assinaturas::Ativar.new(usuario: cobranca.user, plano: cobranca.plano).call
      end
    end
  end
end