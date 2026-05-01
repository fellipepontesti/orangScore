module Jogos
  class Start
    def initialize(jogo:)
      @jogo = jogo
    end

    def call
      if @jogo.em_andamento? || @jogo.finalizado?
        raise Exceptions::ServiceError, "O jogo já foi iniciado ou finalizado."
      end

      @jogo.update!(status: :em_andamento)

      # Notifica os usuários que palpitaram neste jogo
      @jogo.palpites.includes(:user).find_each do |palpite|
        texto = "O jogo #{@jogo.mandante&.nome || 'Mandante'} x #{@jogo.visitante&.nome || 'Visitante'} começou! Acompanhe seu palpite!"
        
        Notificacao.create!(
          user: palpite.user,
          tipo: :system,
          status: :unread,
          texto: texto,
          answered: false
        )
      end
      
      @jogo
    end
  end
end
