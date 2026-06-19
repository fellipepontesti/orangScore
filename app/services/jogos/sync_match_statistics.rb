require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncMatchStatistics
    attr_reader :jogo, :api_key, :year

    def initialize(jogo:)
      @jogo = jogo
      @year = '2026'
      @api_key = ENV['ZAFRONIX_API_KEY'].presence || 'zwc_free_2ea90adb52e1da3babbe8aea'
    end

    def call
      return { success: false, error: "Jogo sem mandante ou visitante definido." } unless jogo.mandante && jogo.visitante

      api_home_names = [
        jogo.mandante.nome.downcase,
        Jogos::TeamMapping.api_search_name(jogo.mandante.nome).to_s.downcase,
        Jogos::TeamMapping.api_team_code(jogo.mandante.nome).to_s.downcase
      ].reject(&:blank?)

      api_away_names = [
        jogo.visitante.nome.downcase,
        Jogos::TeamMapping.api_search_name(jogo.visitante.nome).to_s.downcase,
        Jogos::TeamMapping.api_team_code(jogo.visitante.nome).to_s.downcase
      ].reject(&:blank?)

      url = "https://api.zafronix.com/fifa/worldcup/v1/matches?year=#{year}"
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
      return { success: false, error: "Nenhuma partida encontrada na API." } unless data.is_a?(Hash) && data['data'].present?

      api_match = data['data'].find do |m|
        home_team_api = m['homeTeam'].to_s.downcase
        away_team_api = m['awayTeam'].to_s.downcase
        
        translated_home = Jogos::TeamMapping.translate_country(m['homeTeam']).to_s.downcase
        translated_away = Jogos::TeamMapping.translate_country(m['awayTeam']).to_s.downcase

        ((api_home_names.include?(home_team_api) || api_home_names.include?(translated_home)) &&
         (api_away_names.include?(away_team_api) || api_away_names.include?(translated_away))) ||
        ((api_home_names.include?(away_team_api) || api_home_names.include?(translated_away)) &&
         (api_away_names.include?(home_team_api) || api_away_names.include?(translated_home)))
      end

      unless api_match
        return { success: false, error: "Partida correspondente não encontrada na API." }
      end

      stats = api_match['statistics']
      goals = api_match['goals'] || []
      subs = api_match['substitutions'] || []

      if stats.blank?
        return { success: false, error: "Estatísticas ainda não disponíveis para esta partida na API." }
      end

      info = Jogo.transaction do
        info_local = jogo.informacao_jogo || JogoInformacaoWrapper.get_or_build(jogo)
        info_local.dados = {
          'statistics' => stats,
          'goals' => goals,
          'substitutions' => subs
        }
        info_local.save!

        # Re-consolida os gols e assistências dos jogadores a partir de todas as partidas sincronizadas
        Jogos::SyncSquads.new(import_squad: false, import_goals: true).call

        info_local
      end

      { success: true, stats: stats }
    rescue => e
      Rails.logger.error("Erro ao sincronizar estatísticas do jogo #{jogo.id}: #{e.message}")
      { success: false, error: e.message }
    end

    def self.sync_all(year: '2026')
      api_key = ENV['ZAFRONIX_API_KEY'].presence || 'zwc_free_2ea90adb52e1da3babbe8aea'
      url = "https://api.zafronix.com/fifa/worldcup/v1/matches?year=#{year}"
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
      unless data.is_a?(Hash) && data['data'].present?
        return { success: false, error: "Nenhuma partida encontrada na API." }
      end

      updated_count = 0
      errors = []

      # Carregar todos os jogos locais com mandante e visitante pré-carregados
      jogos_locais = Jogo.includes(:mandante, :visitante).all

      data['data'].each do |api_match|
        next unless api_match['status'] == 'finished'
        stats = api_match['statistics']
        next if stats.blank?

        home_team_api = api_match['homeTeam'].to_s.downcase
        away_team_api = api_match['awayTeam'].to_s.downcase
        
        translated_home = Jogos::TeamMapping.translate_country(api_match['homeTeam']).to_s.downcase
        translated_away = Jogos::TeamMapping.translate_country(api_match['awayTeam']).to_s.downcase

        # Acha o jogo local correspondente
        jogo_local = jogos_locais.find do |jl|
          next unless jl.mandante && jl.visitante
          
          home_names = [
            jl.mandante.nome.downcase,
            Jogos::TeamMapping.api_search_name(jl.mandante.nome).to_s.downcase,
            Jogos::TeamMapping.api_team_code(jl.mandante.nome).to_s.downcase
          ].reject(&:blank?)

          away_names = [
            jl.visitante.nome.downcase,
            Jogos::TeamMapping.api_search_name(jl.visitante.nome).to_s.downcase,
            Jogos::TeamMapping.api_team_code(jl.visitante.nome).to_s.downcase
          ].reject(&:blank?)

          ((home_names.include?(home_team_api) || home_names.include?(translated_home)) &&
           (away_names.include?(away_team_api) || away_names.include?(translated_away))) ||
          ((home_names.include?(away_team_api) || home_names.include?(translated_away)) &&
           (away_names.include?(home_team_api) || away_names.include?(translated_home)))
        end

        if jogo_local
          begin
            InformacaoJogo.transaction do
              info = jogo_local.informacao_jogo || InformacaoJogo.new(jogo_id: jogo_local.id)
              info.dados = {
                'statistics' => stats,
                'goals' => api_match['goals'] || [],
                'substitutions' => api_match['substitutions'] || []
              }
              info.save!
            end
            updated_count += 1
          rescue => e
            errors << "Erro no jogo #{jogo_local.id}: #{e.message}"
          end
        end
      end

      if errors.any?
        { success: true, count: updated_count, warning: "Sincronizado com alguns erros: #{errors.join(', ')}" }
      else
        { success: true, count: updated_count }
      end
    rescue => e
      Rails.logger.error("Erro ao sincronizar estatísticas gerais: #{e.message}")
      { success: false, error: e.message }
    end
  end
end

class JogoInformacaoWrapper
  def self.get_or_build(jogo)
    InformacaoJogo.find_by(jogo_id: jogo.id) || InformacaoJogo.new(jogo_id: jogo.id)
  end
end
