module Cobrancas
  class Confirmar
    def initialize(cobranca:, session:)
      @cobranca = cobranca
      @session = session
      @user = cobranca.user
    end

    def call
      ActiveRecord::Base.transaction do
        @cobranca.update!(
          status: :pago,
          paid_at: Time.current
        )

        Pagamentos::Create.new(cobranca: @cobranca, session: @session).call

        if @user.assinatura.present?
          @user.assinatura.update!(plano: @cobranca.plano)
        else
          @user.create_assinatura!(plano: @cobranca.plano)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "💥 Erro ao confirmar cobrança: #{e.message}"
      raise e
    end
  end
end