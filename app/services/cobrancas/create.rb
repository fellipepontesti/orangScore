module Cobrancas
  class Create
    PLANOS = {
      "doacao" => 500,
      "premium" => 999
    }.freeze

    def self.call(user:, plano:, payment_method:, gateway:, valor_customizado: nil)
      valor = valor_customizado || PLANOS[plano]

      # Desconto temporário de teste para o Fellipe em produção (Premium por 50 centavos)
      if plano == "premium" && user.name.to_s.downcase.include?("fellipe")
        valor = 50
      end

      raise "Plano inválido ou valor não informado" unless valor

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
