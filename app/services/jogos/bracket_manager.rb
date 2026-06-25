module Jogos
  class BracketManager
    # Restrições oficiais de grupos permitidos para cada jogo de terceira colocação (Visitantes da Segunda Fase)
    RESTRICTIONS = {
      74 => %w[A B C D F],
      75 => %w[C D F G H],
      80 => %w[B E F I J],
      82 => %w[A E H I J],
      83 => %w[C E F H I],
      86 => %w[E H I J K],
      88 => %w[E F G I J],
      89 => %w[D E I J L]
    }.freeze

    # Mapeamento do jogo de destino de Oitavas para as fontes da Segunda Fase
    FONTES_OITAVAS = {
      90 => { mandante: 74, visitante: 75 },
      91 => { mandante: 78, visitante: 79 },
      92 => { mandante: 82, visitante: 83 },
      93 => { mandante: 76, visitante: 77 },
      94 => { mandante: 86, visitante: 87 },
      95 => { mandante: 88, visitante: 89 },
      96 => { mandante: 80, visitante: 81 },
      97 => { mandante: 84, visitante: 85 }
    }.freeze

    # Mapeamento de Quartas para as fontes de Oitavas
    FONTES_QUARTAS = {
      98 => { mandante: 90, visitante: 91 },
      99 => { mandante: 94, visitante: 95 },
      100 => { mandante: 92, visitante: 93 },
      101 => { mandante: 96, visitante: 97 }
    }.freeze

    # Mapeamento de Semis para as fontes de Quartas
    FONTES_SEMIS = {
      102 => { mandante: 98, visitante: 99 },
      103 => { mandante: 100, visitante: 101 }
    }.freeze

    # Mapeamento da Final e Terceiro Lugar para as fontes de Semis
    FONTES_FINAL = {
      104 => { mandante: { jogo: 102, tipo: :vencedor }, visitante: { jogo: 103, tipo: :vencedor } },
      105 => { mandante: { jogo: 102, tipo: :perdedor }, visitante: { jogo: 103, tipo: :perdedor } }
    }.freeze

    # Nomes provisórios originais dos jogos para permitir desfazer o preenchimento
    PROVISORIOS_ORIGINAIS = {
      74 => { mandante: "1° E", visitante: "3° ABCDF" },
      75 => { mandante: "1° I", visitante: "3° CDFGH" },
      76 => { mandante: "2° A", visitante: "2° B" },
      77 => { mandante: "2° K", visitante: "2° L" },
      78 => { mandante: "1° F", visitante: "2° C" },
      79 => { mandante: "1° H ", visitante: "2° J" },
      80 => { mandante: "1° D", visitante: "3° BEFIJ" },
      81 => { mandante: "1° C", visitante: "2° F" },
      82 => { mandante: "1° G", visitante: "3° AEHIJ" },
      83 => { mandante: "1° A", visitante: "3° CEFHI" },
      84 => { mandante: "2° E", visitante: "2° I" },
      85 => { mandante: "1° J", visitante: "2° H" },
      86 => { mandante: "1° L", visitante: "3° EHIJK" },
      87 => { mandante: "2° D", visitante: "2° G" },
      88 => { mandante: "1° B", visitante: "3° EFGIJ" },
      89 => { mandante: "1° K", visitante: "3° DEIJL" },
      90 => { mandante: "Venc. Segunda fase 1", visitante: "Venc. Segunda fase 2" },
      91 => { mandante: "Venc. Segunda fase 5", visitante: "Venc. Segunda fase 6" },
      92 => { mandante: "Venc. Segunda fase 9", visitante: "Venc. Segunda fase 10" },
      93 => { mandante: "Venc. Segunda fase 3", visitante: "Venc. Segunda fase 4" },
      94 => { mandante: "Venc. Segunda fase 13", visitante: "Venc. Segunda fase 14" },
      95 => { mandante: "Venc. Segunda fase 15", visitante: "Venc. Segunda fase 16" },
      96 => { mandante: "Venc. Segunda fase 7", visitante: "Venc. Segunda fase 8" },
      97 => { mandante: "Venc. Segunda fase 11", visitante: "Venc. Segunda fase 12" },
      98 => { mandante: "Venc. Oitavas 1", visitante: "Venc. Oitavas 2" },
      99 => { mandante: "Venc. Oitavas 5", visitante: "Venc. Oitavas 6" },
      100 => { mandante: "Venc. Oitavas 3", visitante: "Venc. Oitavas 4" },
      101 => { mandante: "Venc. Oitavas 7", visitante: "Venc. Oitavas 8" },
      102 => { mandante: "Venc. Quartas 1", visitante: "Venc. Quartas 2" },
      103 => { mandante: "Venc. Quartas 3", visitante: "Venc. Quartas 4" },
      104 => { mandante: "Venc. Semifinal 1", visitante: "Venc. Semifinal 2" },
      105 => { mandante: "Perd. Semi1", visitante: "Perd. Semi2" }
    }.freeze

    def self.atualizar
      preencher_segunda_fase
      atualizar_chaves_subsequentes
    end

    def self.resetar
      PROVISORIOS_ORIGINAIS.each do |jogo_id, nomes|
        jogo = Jogo.find_by(id: jogo_id)
        next unless jogo

        jogo.update!(
          mandante_id: nil,
          visitante_id: nil,
          nome_provisorio_mandante: nomes[:mandante],
          nome_provisorio_visitante: nomes[:visitante],
          definir: true,
          status: :times_a_definir
        )
      end
    end

    def self.preencher_segunda_fase
      # Mapeamento direto de mandantes e visitantes baseados em 1º e 2º colocados dos grupos
      mapeamento_direto = {
        74 => { mandante: { grupo: 'E', pos: 0 } },
        75 => { mandante: { grupo: 'I', pos: 0 } },
        76 => { mandante: { grupo: 'A', pos: 1 }, visitante: { grupo: 'B', pos: 1 } },
        77 => { mandante: { grupo: 'K', pos: 1 }, visitante: { grupo: 'L', pos: 1 } },
        78 => { mandante: { grupo: 'F', pos: 0 }, visitante: { grupo: 'C', pos: 1 } },
        79 => { mandante: { grupo: 'H', pos: 0 }, visitante: { grupo: 'J', pos: 1 } },
        80 => { mandante: { grupo: 'D', pos: 0 } },
        81 => { mandante: { grupo: 'C', pos: 0 }, visitante: { grupo: 'F', pos: 1 } },
        82 => { mandante: { grupo: 'G', pos: 0 } },
        83 => { mandante: { grupo: 'A', pos: 0 } },
        84 => { mandante: { grupo: 'E', pos: 1 }, visitante: { grupo: 'I', pos: 1 } },
        85 => { mandante: { grupo: 'J', pos: 0 }, visitante: { grupo: 'H', pos: 1 } },
        86 => { mandante: { grupo: 'L', pos: 0 } },
        87 => { mandante: { grupo: 'D', pos: 1 }, visitante: { grupo: 'G', pos: 1 } },
        88 => { mandante: { grupo: 'B', pos: 0 } },
        89 => { mandante: { grupo: 'K', pos: 0 } }
      }

      grupos = Grupo.all.index_by { |g| g.nome.strip.last }

      # 1. Preenche as posições diretas baseadas em grupos finalizados
      mapeamento_direto.each do |jogo_id, configs|
        jogo = Jogo.find_by(id: jogo_id)
        next unless jogo

        mudou = false

        # Preenche Mandante
        if configs[:mandante]
          letra_grupo = configs[:mandante][:grupo]
          pos = configs[:mandante][:pos]
          g = grupos[letra_grupo]
          if g && grupo_finalizado?(g)
            selecao = g.selecoes.ordenadas[pos]
            if selecao && jogo.mandante_id != selecao.id
              jogo.mandante = selecao
              jogo.nome_provisorio_mandante = nil
              mudou = true
            end
          end
        end

        # Preenche Visitante
        if configs[:visitante]
          letra_grupo = configs[:visitante][:grupo]
          pos = configs[:visitante][:pos]
          g = grupos[letra_grupo]
          if g && grupo_finalizado?(g)
            selecao = g.selecoes.ordenadas[pos]
            if selecao && jogo.visitante_id != selecao.id
              jogo.visitante = selecao
              jogo.nome_provisorio_visitante = nil
              mudou = true
            end
          end
        end

        if mudou
          jogo.definir = false if jogo.mandante_id.present? && jogo.visitante_id.present?
          jogo.save!
        end
      end

      # 2. Preenche os visitantes vindo dos 8 melhores terceiros colocados (apenas se todos os 12 grupos acabaram)
      todos_finalizados = grupos.values.all? { |g| grupo_finalizado?(g) }
      if todos_finalizados
        terceiros = grupos.values.map { |g| g.selecoes.ordenadas[2] }.compact
        # Ordenação dos terceiros colocados conforme tie-breakers da FIFA
        terceiros_ordenados = terceiros.sort_by do |s|
          [
            -s.pontos.to_i,
            -(s.gols.to_i - s.gols_sofridos.to_i),
            -s.gols.to_i,
            s.nome
          ]
        end

        melhores_terceiros = terceiros_ordenados.first(8)
        atribuicoes = emparelhar(melhores_terceiros)

        if atribuicoes
          atribuicoes.each do |jogo_id, terceiro|
            jogo = Jogo.find_by(id: jogo_id)
            if jogo && jogo.visitante_id != terceiro.id
              jogo.visitante = terceiro
              jogo.nome_provisorio_visitante = nil
              jogo.definir = false if jogo.mandante_id.present?
              jogo.save!
            end
          end
        end
      end
    end

    def self.atualizar_chaves_subsequentes
      # Oitavas de Final
      FONTES_OITAVAS.each do |jogo_id, fontes|
        processar_confronto_vencedores(jogo_id, fontes[:mandante], fontes[:visitante])
      end

      # Quartas de Final
      FONTES_QUARTAS.each do |jogo_id, fontes|
        processar_confronto_vencedores(jogo_id, fontes[:mandante], fontes[:visitante])
      end

      # Semifinais
      FONTES_SEMIS.each do |jogo_id, fontes|
        processar_confronto_vencedores(jogo_id, fontes[:mandante], fontes[:visitante])
      end

      # Final e Terceiro Lugar
      FONTES_FINAL.each do |jogo_id, fontes|
        jogo = Jogo.find_by(id: jogo_id)
        next unless jogo

        mudou = false

        # Mandante
        j_m_fonte = Jogo.find_by(id: fontes[:mandante][:jogo])
        if j_m_fonte&.finalizado?
          selecao_m = fontes[:mandante][:tipo] == :vencedor ? determinar_vencedor(j_m_fonte) : determinar_perdedor(j_m_fonte)
          if selecao_m && jogo.mandante_id != selecao_m.id
            jogo.mandante = selecao_m
            jogo.nome_provisorio_mandante = nil
            mudou = true
          end
        end

        # Visitante
        j_v_fonte = Jogo.find_by(id: fontes[:visitante][:jogo])
        if j_v_fonte&.finalizado?
          selecao_v = fontes[:visitante][:tipo] == :vencedor ? determinar_vencedor(j_v_fonte) : determinar_perdedor(j_v_fonte)
          if selecao_v && jogo.visitante_id != selecao_v.id
            jogo.visitante = selecao_v
            jogo.nome_provisorio_visitante = nil
            mudou = true
          end
        end

        if mudou
          jogo.definir = false if jogo.mandante_id.present? && jogo.visitante_id.present?
          jogo.save!
        end
      end
    end

    private

    def self.grupo_finalizado?(grupo)
      jogos = Jogo.where(grupo_id: grupo.id, tipo: :grupo)
      jogos.any? && jogos.all?(&:finalizado?)
    end

    def self.processar_confronto_vencedores(jogo_id, fonte_mandante_id, fonte_visitante_id)
      jogo = Jogo.find_by(id: jogo_id)
      return unless jogo

      mudou = false
      jogo_mandante = Jogo.find_by(id: fonte_mandante_id)
      jogo_visitante = Jogo.find_by(id: fonte_visitante_id)

      if jogo_mandante&.finalizado?
        vencedor_m = determinar_vencedor(jogo_mandante)
        if vencedor_m && jogo.mandante_id != vencedor_m.id
          jogo.mandante = vencedor_m
          jogo.nome_provisorio_mandante = nil
          mudou = true
        end
      end

      if jogo_visitante&.finalizado?
        vencedor_v = determinar_vencedor(jogo_visitante)
        if vencedor_v && jogo.visitante_id != vencedor_v.id
          jogo.visitante = vencedor_v
          jogo.nome_provisorio_visitante = nil
          mudou = true
        end
      end

      if mudou
        jogo.definir = false if jogo.mandante_id.present? && jogo.visitante_id.present?
        jogo.save!
      end
    end

    def self.determinar_vencedor(jogo)
      return nil unless jogo.finalizado?
      if jogo.gols_mandante.to_i > jogo.gols_visitante.to_i
        jogo.mandante
      elsif jogo.gols_visitante.to_i > jogo.gols_mandante.to_i
        jogo.visitante
      else
        nil
      end
    end

    def self.determinar_perdedor(jogo)
      return nil unless jogo.finalizado?
      if jogo.gols_mandante.to_i < jogo.gols_visitante.to_i
        jogo.mandante
      elsif jogo.gols_visitante.to_i < jogo.gols_mandante.to_i
        jogo.visitante
      else
        nil
      end
    end

    # Algoritmo de backtracking para casamento bipartido perfeito dos terceiros colocados
    def self.emparelhar(melhores_terceiros)
      jogos_ids = RESTRICTIONS.keys
      atribuicoes = {}
      
      if resolver_matching(jogos_ids, melhores_terceiros, 0, atribuicoes)
        atribuicoes
      else
        nil
      end
    end

    def self.resolver_matching(jogos_ids, terceiros, index, atribuicoes)
      return true if index >= jogos_ids.size

      jogo_id = jogos_ids[index]
      grupos_permitidos = RESTRICTIONS[jogo_id]

      terceiros.each do |terceiro|
        next if atribuicoes.values.include?(terceiro)

        grupo_letra = terceiro.grupo.nome.strip.last
        if grupos_permitidos.include?(grupo_letra)
          atribuicoes[jogo_id] = terceiro
          if resolver_matching(jogos_ids, terceiros, index + 1, atribuicoes)
            return true
          end
          atribuicoes.delete(jogo_id)
        end
      end

      false
    end
  end
end
