module Notificacoes
  class Create
    def initialize(sender_id, user_id, texto, tipo, liga_id, answered)
      @sender_id = sender_id
      @user_id = user_id
      @texto = texto
      @tipo = tipo
      @liga_id = liga_id
      @answered = answered
    end

    def call
      @notificacao = Notificacao.create!(
        sender_id = @sender_id,
        user_id = @user_id,
        texto = @texto,
        status = :unread,
        liga_id = @liga_id,
        answered = @answered
      )
    end
  end
end
