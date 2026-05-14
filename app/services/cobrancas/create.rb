module Cobrancas
  class Create
    PLANOS = {
      "plus" => 50, # 50 centavos para teste em produção
      "premium" => 1499
    }.freeze

    def self.call(user:, plano:, payment_method:, gateway:)
      valor = PLANOS[plano]

      raise "Plano inválido" unless valor

      Cobranca.create!(
        user: user,
        plano: plano,
        valor: valor,
        status: :pendente,
        gateway: gateway,
        payment_method: payment_method,
        expires_at: 30.minutes.from_now
      )
    end
  end
end