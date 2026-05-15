module Jogos
  class CalculaPontuacao
    def initialize(jogo:)
      @jogo = jogo
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
      end

      atribuir_bonus_campeao if @jogo.tipo == 'final'
    end

    private

    def calcular_pontos_palpite(palpite)
      if acertou_placar_exato?(palpite)
        [10, "Placar Exato"]
      elsif acertou_vencedor_ou_empate?(palpite) && acertou_gols_de_um_time?(palpite)
        [7, "Vencedor/Empate + Gols de um time"]
      elsif acertou_vencedor_ou_empate?(palpite)
        [5, "Apenas Vencedor/Empate"]
      else
        [2, "Participação"]
      end
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
