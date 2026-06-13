module Jogos
  class FetchOdds
    def self.sync_all
      jogos = Jogo.where.not(status: :finalizado)
                  .where.not(mandante_id: nil)
                  .where.not(visitante_id: nil)
      updated = 0
      errors  = []

      jogos.find_each do |jogo|
        result = new(jogo: jogo).call
        if result[:success]
          updated += 1
        else
          errors << { jogo_id: jogo.id, error: result[:error] }
        end
      end

      { updated: updated, errors: errors }
    end

    def initialize(jogo:)
      @jogo = jogo
    end

    def call
      return { success: false, error: "Jogo sem mandante ou visitante definido." } unless @jogo.mandante && @jogo.visitante

      calculate_local_odds

      {
        success: true,
        method: :local,
        odds: {
          home: @jogo.prob_mandante,
          draw: @jogo.prob_empate,
          away: @jogo.prob_visitante
        }
      }
    rescue => e
      Rails.logger.error "Erro no cálculo local de odds do jogo #{@jogo.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def calculate_local_odds
      hm = @jogo.mandante
      aw = @jogo.visitante

      hm_jogos = (hm.qtd_jogos || 0)
      aw_jogos = (aw.qtd_jogos || 0)

      if hm_jogos == 0 && aw_jogos == 0
        @jogo.update_columns(prob_mandante: 45, prob_empate: 25, prob_visitante: 30)
        return
      end

      hm_ppg = (hm.pontos || 0).to_f / [hm_jogos, 1].max
      aw_ppg = (aw.pontos || 0).to_f / [aw_jogos, 1].max

      hm_gf  = (hm.gols || 0).to_f / [hm_jogos, 1].max
      aw_gf  = (aw.gols || 0).to_f / [aw_jogos, 1].max

      hm_gs  = (hm.gols_sofridos || 0).to_f / [hm_jogos, 1].max
      aw_gs  = (aw.gols_sofridos || 0).to_f / [aw_jogos, 1].max

      f_home = (hm_ppg * 15.0) + (hm_gf * 10.0) - (hm_gs * 8.0) + 15.0
      f_away = (aw_ppg * 15.0) + (aw_gf * 10.0) - (aw_gs * 8.0) + 15.0

      h2h = confrontos_diretos(hm.id, aw.id)

      if h2h[:total] > 0
        h2h_bonus_home = (h2h[:home_wins].to_f / h2h[:total]) * 8.0
        h2h_bonus_away = (h2h[:away_wins].to_f / h2h[:total]) * 8.0
        f_home += h2h_bonus_home
        f_away += h2h_bonus_away
      end

      f_home *= 1.05

      f_home += Math.log((hm.qtd_torcedores || 0) + 1) * 0.5
      f_away += Math.log((aw.qtd_torcedores || 0) + 1) * 0.5

      f_home = [f_home, 1.0].max
      f_away = [f_away, 1.0].max

      hm_empates_rate = (hm.empates || 0).to_f / [hm_jogos, 1].max
      aw_empates_rate = (aw.empates || 0).to_f / [aw_jogos, 1].max

      h2h_draw_bonus = h2h[:total] > 0 ? (h2h[:draws].to_f / h2h[:total]) * 6.0 : 0.0
      f_draw = ((hm_empates_rate + aw_empates_rate) * 5.0) + 6.0 + h2h_draw_bonus

      total  = f_home + f_away + f_draw
      p_home = ((f_home / total) * 100).round
      p_away = ((f_away / total) * 100).round
      p_draw = 100 - p_home - p_away

      if p_draw < 1
        p_draw = 1
        p_home = 100 - p_draw - p_away
      end

      @jogo.update_columns(
        prob_mandante: p_home,
        prob_empate:   p_draw,
        prob_visitante: p_away
      )
    end

    def confrontos_diretos(hm_id, aw_id)
      jogos_h2h = Jogo.finalizado.where(
        "(mandante_id = :hm AND visitante_id = :aw) OR (mandante_id = :aw AND visitante_id = :hm)",
        hm: hm_id, aw: aw_id
      )

      total      = jogos_h2h.count
      home_wins  = 0
      away_wins  = 0
      draws      = 0

      jogos_h2h.each do |j|
        gm = j.gols_mandante || 0
        gv = j.gols_visitante || 0

        if gm == gv
          draws += 1
        elsif j.mandante_id == hm_id
          gm > gv ? home_wins += 1 : away_wins += 1
        else
          gv > gm ? home_wins += 1 : away_wins += 1
        end
      end

      { total: total, home_wins: home_wins, away_wins: away_wins, draws: draws }
    end
  end
end
