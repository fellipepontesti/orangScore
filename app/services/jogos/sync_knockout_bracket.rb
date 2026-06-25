require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncKnockoutBracket
    attr_reader :api_key, :year

    def initialize(year: '2026')
      @year = year.presence || '2026'
      @api_key = ENV['ZAFRONIX_API_KEY'].presence || 'zwc_free_2ea90adb52e1da3babbe8aea'
    end

    def call
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

      updated_count = 0
      warnings = []

      # Filtra partidas de mata-mata (r32, r16, qf, sf, thirdPlace, final)
      knockout_matches = data['data'].reject { |m| m['stage'].to_s.include?('group') }

      Jogo.transaction do
        knockout_matches.each do |api_match|
          match_no = api_match['matchNo']
          next if match_no.nil?

          # Só processamos jogos do mata-mata (a partir de 73)
          next unless match_no >= 73

          # Mapeamento do matchNo para o jogo local ID
          jogo_id = case match_no
                    when 104 then 104 # Final
                    when 103 then 105 # Terceiro Lugar
                    else match_no + 1
                    end

          jogo_local = Jogo.find_by(id: jogo_id)
          next unless jogo_local

          home_team_name = api_match['homeTeam'].to_s.strip
          away_team_name = api_match['awayTeam'].to_s.strip

          next if home_team_name.blank? || away_team_name.blank?

          # Traduz/mapeia seleções
          mandante_local = encontrar_selecao(home_team_name)
          visitante_local = encontrar_selecao(away_team_name)

          unless mandante_local
            warnings << "Seleção '#{home_team_name}' do jogo ##{match_no} da API não encontrada no banco local."
            next
          end

          unless visitante_local
            warnings << "Seleção '#{away_team_name}' do jogo ##{match_no} da API não encontrada no banco local."
            next
          end

          # Atualiza se mudou
          mudou = false

          if jogo_local.mandante_id != mandante_local.id
            jogo_local.mandante = mandante_local
            jogo_local.nome_provisorio_mandante = nil
            mudou = true
          end

          if jogo_local.visitante_id != visitante_local.id
            jogo_local.visitante = visitante_local
            jogo_local.nome_provisorio_visitante = nil
            mudou = true
          end

          if mudou
            jogo_local.definir = false
            jogo_local.status = :programado if jogo_local.times_a_definir?
            jogo_local.save!
            updated_count += 1
          end
        end
      end

      { success: true, updated_count: updated_count, warnings: warnings }
    rescue => e
      Rails.logger.error("Erro ao sincronizar chaves do mata-mata: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def encontrar_selecao(name)
      # Primeiro tenta correspondência exata ou via mapeamento complementar
      Selecao.all.find do |s|
        local_name = s.nome.to_s.strip
        Jogos::TeamMapping.api_search_name(local_name).to_s.downcase == name.downcase ||
        Jogos::TeamMapping.api_team_code(local_name).to_s.downcase == name.downcase ||
        local_name.downcase == name.downcase ||
        Jogos::TeamMapping.translate_country(name).to_s.downcase == local_name.downcase
      end
    end
  end
end
