module Jogos
  class StatusNotifier
    def initialize(jogo:)
      @jogo = jogo
    end

    def call
      return unless notify_status?

      users_to_notify.find_each do |user|
        Notificacao.create!(
          user: user,
          tipo: :system,
          status: :unread,
          texto: notification_text
        )
      end
    end

    private

    attr_reader :jogo

    def notify_status?
      jogo.saved_change_to_status? && users_to_notify.exists?
    end

    def users_to_notify
      User.where(id: jogo.palpites.select(:user_id).distinct)
    end

    def notification_text
      case jogo.status
      when 'em_andamento'
        "O jogo #{game_title} começou! Acompanhe seu palpite e fique por dentro do placar."
      when 'finalizado'
        "O jogo #{game_title} terminou em #{score_label}. Confira a sua pontuação e veja se acertou o resultado."
      when 'times_a_definir'
        "O jogo #{game_title} agora está com times a definir. Fique de olho nas próximas atualizações."
      when 'programado'
        "O jogo #{game_title} está programado. Seu palpite já está registrado — boa sorte!"
      else
        "O status do jogo #{game_title} mudou para #{jogo.status.humanize}."
      end
    end

    def game_title
      mandante_name = jogo.mandante&.nome.presence || jogo.nome_provisorio_mandante.presence || 'Mandante'
      visitante_name = jogo.visitante&.nome.presence || jogo.nome_provisorio_visitante.presence || 'Visitante'
      "#{mandante_name} x #{visitante_name}"
    end

    def score_label
      if jogo.gols_mandante.present? || jogo.gols_visitante.present?
        "#{jogo.gols_mandante.to_i} x #{jogo.gols_visitante.to_i}"
      else
        'a definir'
      end
    end
  end
end
