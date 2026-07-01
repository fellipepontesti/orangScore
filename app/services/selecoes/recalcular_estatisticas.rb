module Selecoes
  class RecalcularEstatisticas
    def self.para_grupo(grupo)
      return unless grupo
      grupo.selecoes.each do |selecao|
        recalcular(selecao)
      end
    end

    def self.recalcular(selecao)
      return unless selecao

      pontos = 0
      qtd_jogos = 0
      vitorias = 0
      derrotas = 0
      empates = 0
      gols = 0
      gols_sofridos = 0

      # Jogos como mandante na fase de grupos
      Jogo.grupo.where(mandante_id: selecao.id).find_each do |jogo|
        if jogo.finalizado? || jogo.em_andamento?
          gols += jogo.gols_mandante || 0
          gols_sofridos += jogo.gols_visitante || 0
          
          if jogo.finalizado?
            qtd_jogos += 1
            if (jogo.gols_mandante || 0) > (jogo.gols_visitante || 0)
              vitorias += 1
              pontos += 3
            elsif (jogo.gols_mandante || 0) < (jogo.gols_visitante || 0)
              derrotas += 1
            else
              empates += 1
              pontos += 1
            end
          end
        end
      end

      # Jogos como visitante na fase de grupos
      Jogo.grupo.where(visitante_id: selecao.id).find_each do |jogo|
        if jogo.finalizado? || jogo.em_andamento?
          gols += jogo.gols_visitante || 0
          gols_sofridos += jogo.gols_mandante || 0
          
          if jogo.finalizado?
            qtd_jogos += 1
            if (jogo.gols_visitante || 0) > (jogo.gols_mandante || 0)
              vitorias += 1
              pontos += 3
            elsif (jogo.gols_visitante || 0) < (jogo.gols_mandante || 0)
              derrotas += 1
            else
              empates += 1
              pontos += 1
            end
          end
        end
      end

      selecao.update_columns(
        pontos: pontos,
        qtd_jogos: qtd_jogos,
        vitorias: vitorias,
        derrotas: derrotas,
        empates: empates,
        gols: gols,
        gols_sofridos: gols_sofridos
      )

      # Recalcula as odds locais para todos os próximos jogos programados desta seleção
      Jogo.where.not(status: :finalizado)
          .where("mandante_id = ? OR visitante_id = ?", selecao.id, selecao.id)
          .find_each do |jogo|
            Jogos::FetchOdds.new(jogo: jogo).call
          end
    end
  end
end
