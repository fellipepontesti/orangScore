module Assinaturas
  class Ativar
    def initialize(usuario:, plano:)
      @usuario = usuario
      @plano = plano
    end

    def call
      return if @plano == "doacao"

      assinatura = @usuario.assinatura || @usuario.build_assinatura
      assinatura.update!(
        plano: @plano,
        ativa: true
      )
    end
  end
end