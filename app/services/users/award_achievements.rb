module Users
  class AwardAchievements
    SLUGS = {
      # Pontuação
      pontos_2: 'pontos_2',
      pontos_5: 'pontos_5',
      pontos_7: 'pontos_7',
      pontos_10: 'pontos_10',
      pontos_25: 'pontos_25',
      # Comportamento
      primeiro_palpite: 'primeiro_palpite',
      mestre_do_empate: 'mestre_do_empate',
      zebra: 'zebra',
      pe_quente: 'pe_quente',
      tudo_ou_nada: 'tudo_ou_nada',
      criador_de_ligas: 'criador_de_ligas',
      premium_user: 'premium_user',
      # Novas Conquistas
      palpites_50: 'palpites_50',
      palpites_90: 'palpites_90',
      palpites_100: 'palpites_100',
      perfeito_10: 'perfeito_10',
      amigos_5: 'amigos_5',
      referral_bonus: 'referral_bonus',
      liga_cheia: 'liga_cheia',
      palpite_ultimo_segundo: 'palpite_ultimo_segundo',
      rei_do_mata_mata: 'rei_do_mata_mata',
      azarado: 'azarado',
      palpitador_preciso: 'palpitador_preciso'
    }.freeze

    def self.award(user, slug, jogo = nil)
      conquista = Conquista.find_by(slug: slug)
      return unless conquista

      unless UserConquista.exists?(user: user, conquista: conquista)
        UserConquista.create!(
          user: user,
          conquista: conquista,
          jogo: jogo
        )
      end
    end

    def self.check_palpite_achievements(user)
      palpites_count = user.palpites.count
      if palpites_count >= 1
        award(user, SLUGS[:primeiro_palpite])
      end
      if palpites_count >= 50
        award(user, SLUGS[:palpites_50])
      end
      if palpites_count >= 90
        award(user, SLUGS[:palpites_90])
      end
      if palpites_count >= 100
        award(user, SLUGS[:palpites_100])
      end

      total_jogos_grupo = Jogo.where(tipo: :grupo, definir: false).count
      if total_jogos_grupo > 0 && user.palpites.joins(:jogo).where(jogos: { tipo: :grupo }).count == total_jogos_grupo
        award(user, SLUGS[:tudo_ou_nada])
      end
    end

    def self.check_match_finished_achievements(user, jogo)
      point = UserPoint.find_by(user: user, jogo: jogo)
      return unless point

      case point.pontos
      when 2
        award(user, SLUGS[:pontos_2], jogo)
      when 5
        award(user, SLUGS[:pontos_5], jogo)
      when 7
        award(user, SLUGS[:pontos_7], jogo)
      when 10
        award(user, SLUGS[:pontos_10], jogo)
      when 25
        award(user, SLUGS[:pontos_25], jogo)
      end

      # Mestre do Empate
      if point.pontos == 10
        palpite = user.palpites.find_by(jogo_id: jogo.id)
        if palpite && palpite.gols_casa == palpite.gols_fora
          award(user, SLUGS[:mestre_do_empate], jogo)
        end
      end

      # Perfeito 10 (10 placares exatos)
      if user.user_points.where(motivo: "Placar Exato").count >= 10
        award(user, SLUGS[:perfeito_10])
      end

      # Palpitador Preciso (3 placares exatos)
      if user.user_points.where(motivo: "Placar Exato").count >= 3
        award(user, SLUGS[:palpitador_preciso])
      end

      # Azarado (errou placar exato por apenas 1 gol de diferença, ganhando 7 pontos)
      if point.pontos == 7
        award(user, SLUGS[:azarado], jogo)
      end

      # Zebra
      if point.pontos >= 5
        palpite = user.palpites.find_by(jogo_id: jogo.id)
        if palpite
          vencedor_mandante = jogo.gols_mandante > jogo.gols_visitante
          vencedor_visitante = jogo.gols_visitante > jogo.gols_mandante
          
          is_zebra = false
          if vencedor_mandante && jogo.prob_mandante.present? && jogo.prob_mandante < 25
            is_zebra = true
          elsif vencedor_visitante && jogo.prob_visitante.present? && jogo.prob_visitante < 25
            is_zebra = true
          end

          award(user, SLUGS[:zebra], jogo) if is_zebra
        end
      end

      # Sequência Quente
      last_5_points = user.user_points.joins(:jogo)
                                      .where(jogos: { status: :finalizado })
                                      .order("jogos.data DESC")
                                      .limit(5)
                                      .pluck(:pontos)
      if last_5_points.size == 5 && last_5_points.all? { |pts| pts >= 5 }
        award(user, SLUGS[:pe_quente], jogo)
      end
    end

    def self.check_referrals_achievements(user)
      ref_count = user.referrals_count.to_i
      if ref_count >= 1
        award(user, SLUGS[:referral_bonus])
      end
    end

    def self.check_socializacao(user)
      # Verifica se o usuário é owner de alguma liga com >= 5 membros aceitos
      user.ligas.each do |liga|
        if liga.liga_membros.accepted.count >= 5
          award(user, SLUGS[:amigos_5])
          return
        end
      end
    end

    def self.check_liga_cheia(user)
      # Verifica se participa de alguma liga com >= 10 membros aceitos
      user.ligas_participadas.each do |liga|
        if liga.liga_membros.accepted.count >= 10
          award(user, SLUGS[:liga_cheia])
          return
        end
      end

      # Também verifica se criou alguma liga com >= 10 membros aceitos
      user.ligas.each do |liga|
        if liga.liga_membros.accepted.count >= 10
          award(user, SLUGS[:liga_cheia])
          return
        end
      end
    end

    def self.check_palpite_ultimo_segundo(user, palpite)
      jogo = palpite.jogo
      return unless jogo
      if palpite.updated_at >= (jogo.data - 5.minutes) && palpite.updated_at <= jogo.data
        award(user, SLUGS[:palpite_ultimo_segundo], jogo)
      end
    end

    def self.check_rei_do_mata_mata(user)
      mata_mata_hits = user.user_points.joins(:jogo)
                           .where.not(jogos: { tipo: :grupo })
                           .where("user_points.pontos >= 5")
                           .count
      if mata_mata_hits >= 5
        award(user, SLUGS[:rei_do_mata_mata])
      end
    end

    # Verifica e concede retroativamente todas as conquistas cabíveis para o histórico do usuário
    def self.check_retroactive_achievements(user)
      check_palpite_achievements(user) if user.palpites.any?
      award(user, SLUGS[:criador_de_ligas]) if user.ligas.any?
      award(user, SLUGS[:premium_user]) if user.premium?
      check_referrals_achievements(user)
      check_socializacao(user)
      check_liga_cheia(user)
      check_rei_do_mata_mata(user)

      user.palpites.includes(:jogo).each do |palpite|
        check_palpite_ultimo_segundo(user, palpite)
      end

      user.user_points.includes(:jogo).find_each do |up|
        check_match_finished_achievements(user, up.jogo)
      end
    end
  end
end
