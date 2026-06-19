require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncSquads
    attr_reader :selecao, :api_name, :year, :api_key, :import_squad, :import_goals, :warnings

    def initialize(selecao: nil, api_name: nil, year: '2026', import_squad: true, import_goals: true)
      @selecao = selecao
      @api_name = api_name.to_s.strip if api_name
      @year = year.presence || '2026'
      @api_key = ENV['ZAFRONIX_API_KEY'].presence || 'zwc_free_2ea90adb52e1da3babbe8aea'
      @import_squad = import_squad
      @import_goals = import_goals
      @warnings = []
    end

    def call
      @warnings = []
      result = { success: true }

      if import_squad
        url = "https://api.zafronix.com/fifa/worldcup/v1/tournaments/#{year}"
        uri = URI(url)
        
        req = Net::HTTP::Get.new(uri)
        req['X-API-Key'] = api_key

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
          return { success: false, error: "Erro na chamada da API: #{res.code} #{res.message}" }
        end

        data = JSON.parse(res.body)
        
        unless data.is_a?(Hash) && data['teams'].present?
          return { success: false, error: "Resposta da API com formato inesperado ou sem seleções." }
        end

        if selecao.present?
          result = sync_single_team(data['teams'])
        else
          result = sync_all_teams(data['teams'])
        end

        if result[:warning].present?
          @warnings << result[:warning]
        end
      end

      if result[:success] && import_goals
        consolidate_goals_from_matches
      end

      result[:warnings] = @warnings if @warnings.present?
      result
    rescue => e
      Rails.logger.error("Erro ao sincronizar elenco (Ano: #{year}): #{e.message}")
      { success: false, error: e.message, warnings: @warnings }
    end

    private

    def sync_single_team(teams_json)
      team_data = teams_json.find do |t|
        t['name'].to_s.downcase == api_name.downcase ||
          t['code'].to_s.downcase == api_name.downcase ||
          t['iso'].to_s.downcase == api_name.downcase
      end

      unless team_data
        return { success: false, error: "Seleção \"#{api_name}\" não encontrada na API do Zafronix para o ano #{year}." }
      end

      squad = team_data['squad']
      if squad.blank?
        return { success: false, error: "Nenhum jogador encontrado na convocação desta seleção na API." }
      end

      players_imported = 0

      Jogador.transaction do
        selecao.jogadores.destroy_all

        squad.each do |p|
          Jogador.create!(
            selecao: selecao,
            nome: p['name'],
            numero: p['jersey'],
            posicao: p['position'],
            data_nascimento: p['born'],
            idade_torneio: p['ageAtTournament'],
            clube: p.dig('club', 'name'),
            clube_pais: Jogos::TeamMapping.translate_country(p.dig('club', 'country')),
            capitao: p['captain'] || false,
            gols: p['goals'] || 0,
            assistencias: p['assists'] || p['assistencias'] || p['goals_assists'] || 0
          )
          players_imported += 1
        end
      end

      { success: true, count: players_imported }
    end

    def sync_all_teams(teams_json)
      teams_imported = 0
      players_imported = 0
      errors = []

      # Carregar todas as seleções cadastradas localmente
      selecoes_locais = Selecao.all

      selecoes_locais.each do |selecao_local|
        next if selecao_local.nome == 'A definir'

        # Busca correspondente na resposta da API
        api_name_en = Jogos::TeamMapping.api_search_name(selecao_local.nome)
        api_code = Jogos::TeamMapping.api_team_code(selecao_local.nome)

        team_data = teams_json.find do |t|
          t['name'].to_s.downcase == api_name_en.downcase ||
            t['code'].to_s.downcase == api_code.to_s.downcase ||
            t['name'].to_s.downcase == selecao_local.nome.downcase
        end

        next unless team_data

        squad = team_data['squad']
        next if squad.blank?

        begin
          Jogador.transaction do
            selecao_local.jogadores.destroy_all
            squad.each do |p|
              Jogador.create!(
                selecao: selecao_local,
                nome: p['name'],
                numero: p['jersey'],
                posicao: p['position'],
                data_nascimento: p['born'],
                idade_torneio: p['ageAtTournament'],
                clube: p.dig('club', 'name'),
                clube_pais: Jogos::TeamMapping.translate_country(p.dig('club', 'country')),
                capitao: p['captain'] || false,
                gols: p['goals'] || 0,
                assistencias: p['assists'] || p['assistencias'] || p['goals_assists'] || 0
              )
              players_imported += 1
            end
          end
          teams_imported += 1
        rescue => e
          errors << "Erro na seleção #{selecao_local.nome}: #{e.message}"
        end
      end

      if errors.any?
        { success: true, count: players_imported, teams_count: teams_imported, warning: "Sincronizado com alguns erros: #{errors.join(', ')}" }
      else
        { success: true, count: players_imported, teams_count: teams_imported }
      end
    end

    def self.clean_player_name(raw_name)
      return "" if raw_name.blank?
      clean = raw_name.split(/\s+\d+/).first.to_s
      clean = clean.gsub(/\b(pen|o\.?g\.?)\b/i, "")
      clean.strip
    end

    def self.names_match?(lineup_player_name, raw_scorer_name)
      scorer = clean_player_name(raw_scorer_name)
      return false if scorer.blank?

      lineup_name = lineup_player_name.to_s.strip

      s_norm = I18n.transliterate(scorer).downcase.gsub(/[^a-z0-9\s\.]/, "")
      l_norm = I18n.transliterate(lineup_name).downcase.gsub(/[^a-z0-9\s]/, "")

      s_flat = s_norm.gsub(/[^a-z0-9]/, "")
      l_flat = l_norm.gsub(/[^a-z0-9]/, "")
      return true if l_flat.include?(s_flat) || s_flat.include?(l_flat)

      if s_norm =~ /^([a-z])\.\s+(.+)$/
        initial = $1
        lastname = $2

        parts = l_norm.split(/\s+/)
        first_part = parts.first.to_s
        last_parts = parts[1..-1].to_a.join(" ")

        clean_lastname = lastname.gsub(/[^a-z0-9]/, "")
        clean_last_parts = last_parts.gsub(/[^a-z0-9]/, "")
        clean_l_norm = l_norm.gsub(/[^a-z0-9]/, "")

        if first_part.start_with?(initial) && (clean_last_parts.include?(clean_lastname) || clean_l_norm.include?(clean_lastname))
          return true
        end
      end

      if s_flat.size > 2
        l_parts = l_norm.split(/\s+/)
        return true if l_parts.any? { |p| p.gsub(/[^a-z0-9]/, "") == s_flat }
      end

      false
    end

    def consolidate_goals_from_matches
      url = "https://api.zafronix.com/fifa/worldcup/v1/matches?year=#{year}"
      uri = URI(url)
      
      req = Net::HTTP::Get.new(uri)
      req['X-API-Key'] = api_key

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      return unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      return unless data.is_a?(Hash) && data['data'].present?

      # Zera os gols e assistências antes de recomputar
      if selecao.present?
        selecao.jogadores.update_all(gols: 0, assistencias: 0)
      else
        Jogador.update_all(gols: 0, assistencias: 0)
      end

      data['data'].each do |match|
        next unless match['status'] == 'finished'

        goals = match['goals']
        next if goals.blank?

        lineups = match['lineups']
        if lineups.blank?
          @warnings << "Partida #{match['homeTeam']} x #{match['awayTeam']} não possui lineups (escalações) na API."
          next
        end

        goals.each do |g|
          scorer = g['scorer']
          team_side = g['team']
          next if scorer.blank? || !team_side.in?(%w[home away])

          # Ignorar own goals (gols contra)
          next if scorer.downcase =~ /\b(o\.?g\.?|own\s+goal)\b/

          team_name = team_side == 'home' ? match['homeTeam'] : match['awayTeam']
          
          selecao_local = Selecao.all.find do |s|
            local_name = s.nome.to_s.strip
            Jogos::TeamMapping.api_search_name(local_name).to_s.downcase == team_name.downcase ||
            Jogos::TeamMapping.api_team_code(local_name).to_s.downcase == team_name.downcase ||
            local_name.downcase == team_name.downcase ||
            Jogos::TeamMapping.translate_country(team_name).to_s.downcase == local_name.downcase
          end

          unless selecao_local
            @warnings << "Seleção da API '#{team_name}' não encontrada no banco local."
            next
          end
          next if selecao.present? && selecao.id != selecao_local.id

          team_lineup = lineups[team_side]
          if team_lineup.blank?
            @warnings << "Escalação do time '#{team_name}' (lado #{team_side}) está vazia ou incompleta na partida #{match['homeTeam']} x #{match['awayTeam']}."
            next
          end

          player_in_lineup = team_lineup.find do |p|
            Jogos::SyncSquads.names_match?(p['player'], scorer)
          end

          if player_in_lineup
            jogador_local = selecao_local.jogadores.find_by(numero: player_in_lineup['number'])
            unless jogador_local
              jogador_local = selecao_local.jogadores.find do |j|
                Jogos::SyncSquads.names_match?(j.nome, player_in_lineup['player'])
              end
            end

            if jogador_local
              jogador_local.increment!(:gols)
            else
              @warnings << "Jogador '#{scorer}' (número #{player_in_lineup['number']} / nome API '#{player_in_lineup['player']}') da seleção '#{selecao_local.nome}' não foi encontrado no elenco local."
            end
          else
            @warnings << "Jogador '#{scorer}' marcado no gol não foi encontrado na escalação (lineup) do time '#{team_name}'."
          end

          # Assistência
          assist = g['assist']
          if assist.present?
            assist_in_lineup = team_lineup.find do |p|
              Jogos::SyncSquads.names_match?(p['player'], assist)
            end

            if assist_in_lineup
              jogador_assist = selecao_local.jogadores.find_by(numero: assist_in_lineup['number'])
              unless jogador_assist
                jogador_assist = selecao_local.jogadores.find do |j|
                  Jogos::SyncSquads.names_match?(j.nome, assist_in_lineup['player'])
                end
              end

              if jogador_assist
                jogador_assist.increment!(:assistencias)
              else
                @warnings << "Jogador de assistência '#{assist}' (número #{assist_in_lineup['number']} / nome API '#{assist_in_lineup['player']}') da seleção '#{selecao_local.nome}' não foi encontrado no elenco local."
              end
            else
              @warnings << "Jogador da assistência '#{assist}' não foi encontrado na escalação (lineup) do time '#{team_name}'."
            end
          end
        end
      end
    end
  end
end
