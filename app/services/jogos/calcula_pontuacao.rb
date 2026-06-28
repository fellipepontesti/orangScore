module Jogos
  class CalculaPontuacao
    def initialize(jogo:)
      @jogo = jogo
    end

    def self.calcular_pontos_em_memoria(palpite, gols_mandante, gols_visitante)
      return 0 if gols_mandante.nil? || gols_visitante.nil?

      palpite_m = palpite.gols_casa.to_i
      palpite_v = palpite.gols_fora.to_i
      gols_m = gols_mandante.to_i
      gols_v = gols_visitante.to_i

      pontos = if palpite_m == gols_m && palpite_v == gols_v
        10
      elsif (gols_m <=> gols_v) == (palpite_m <=> palpite_v) && (palpite_m == gols_m || palpite_v == gols_v)
        7
      elsif (gols_m <=> gols_v) == (palpite_m <=> palpite_v)
        5
      else
        2
      end

      # Bônus de pênaltis no cálculo em memória
      jogo = palpite.jogo
      if jogo && jogo.tipo != 'grupo' && gols_m == gols_v && palpite_m == palpite_v
        if palpite.vencedor_penaltis_id.present? && palpite.vencedor_penaltis_id == jogo.vencedor_penaltis_id
          pontos += 1
        end
      end

      pontos
    end

    def call
      return unless @jogo.finalizado?

      @jogo.palpites.find_each do |palpite|
        pontos, motivo = calcular_pontos_palpite(palpite)

        UserPoint.create!(
          user: palpite.user,
          jogo: @jogo,
          pontos: pontos,
          motivo: motivo
        )

        Users::AwardAchievements.check_match_finished_achievements(palpite.user, @jogo)
      end

      # Conquista "Deu Ruim": verifica usuários com a seleção eliminada
      Users::AwardAchievements.check_deu_ruim(@jogo) unless @jogo.tipo == 'grupo'

      atribuir_bonus_campeao if @jogo.tipo == 'final'
    end

    private

    def calcular_pontos_palpite(palpite)
      pontos, motivo = if acertou_placar_exato?(palpite)
        [10, "Placar Exato"]
      elsif acertou_vencedor_ou_empate?(palpite) && acertou_gols_de_um_time?(palpite)
        [7, "Vencedor/Empate + Gols de um time"]
      elsif acertou_vencedor_ou_empate?(palpite)
        [5, "Apenas Vencedor/Empate"]
      else
        [2, "Participação"]
      end

      # Regra especial de mata-mata para decisões por pênaltis
      if @jogo.tipo != 'grupo' && @jogo.gols_mandante == @jogo.gols_visitante && palpite.gols_casa == palpite.gols_fora
        if palpite.vencedor_penaltis_id.present? && palpite.vencedor_penaltis_id == @jogo.vencedor_penaltis_id
          pontos += 1
          motivo += " + Bônus de Pênaltis"
        end
      end

      [pontos, motivo]
    end

    def acertou_placar_exato?(palpite)
      palpite.gols_casa == @jogo.gols_mandante && palpite.gols_fora == @jogo.gols_visitante
    end

    def acertou_vencedor_ou_empate?(palpite)
      resultado_jogo = (@jogo.gols_mandante <=> @jogo.gols_visitante)
      resultado_palpite = (palpite.gols_casa <=> palpite.gols_fora)
      
      resultado_jogo == resultado_palpite
    end

    def acertou_gols_de_um_time?(palpite)
      palpite.gols_casa == @jogo.gols_mandante || palpite.gols_fora == @jogo.gols_visitante
    end

    def atribuir_bonus_campeao
      vencedor_id = determinar_campeao
      return unless vencedor_id

      User.where(selecao_id: vencedor_id).find_each do |user|
        UserPoint.create!(
          user: user,
          jogo: @jogo,
          pontos: 25,
          motivo: "Campeão do Torneio"
        )
        Users::AwardAchievements.award(user, 'pontos_25', @jogo)
      end
    end

    def determinar_campeao
      if @jogo.gols_mandante > @jogo.gols_visitante
        @jogo.mandante_id
      elsif @jogo.gols_visitante > @jogo.gols_mandante
        @jogo.visitante_id
      else
        nil
      end
    end
  end
end
