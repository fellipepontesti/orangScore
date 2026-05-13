module Assinaturas
  class Ativar
    def initialize(usuario:, plano:)
      @usuario = usuario
      @plano = plano
    end

    def call
      assinatura = @usuario.assinatura || @usuario.build_assinatura
      assinatura.update!(
        plano: @plano,
        ativa: true
      )
    end
  end
end