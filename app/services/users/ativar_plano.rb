module Users
  class AtivarPlano
    def initialize(usuario:)
      @usuario = usuario
    end

    def call
      assinatura = @usuario.assinatura_atual

      @usuario.update!(
        plano_ativo: true,
        ultimo_pagamento_em: Time.current,
        assinatura_atual_id: assinatura&.id
      )
    end
  end
end