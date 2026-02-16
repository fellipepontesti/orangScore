module Notificacoes
  class Create
    def initialize(sender_id, user_id, texto, tipo, liga_id)
      @sender_id = sender_id
      @user_id = user_id
      @texto = texto
      @tipo = tipo
      @liga_id = liga_id
    end

    def call
      @notificacao = Notificacao.create!(
        sender_id = @sender_id,
        user_id = @user_id,
        texto = @texto,
        status = :unread,
        liga_id = @liga_id
      )
    end
  end
end
