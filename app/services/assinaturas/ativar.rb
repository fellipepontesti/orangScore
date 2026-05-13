module Assinaturas
  class Ativar
    def initialize(usuario:, plano:)
      @usuario = usuario
      @plano = plano
    end

    def call
      Assinatura.find_or_create_by!(
        usuario: @usuario,
        plano: @plano
      )
    end
  end
end