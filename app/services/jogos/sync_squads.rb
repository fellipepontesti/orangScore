require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncSquads
    attr_reader :selecao, :api_name, :year, :api_key

    def initialize(selecao: nil, api_name: nil, year: '2026')
      @selecao = selecao
      @api_name = api_name.to_s.strip if api_name
      @year = year.presence || '2026'
      @api_key = ENV['ZAFRONIX_API_KEY'].presence || 'zwc_free_2ea90adb52e1da3babbe8aea'
    end

    def call
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
        sync_single_team(data['teams'])
      else
        sync_all_teams(data['teams'])
      end
    rescue => e
      Rails.logger.error("Erro ao sincronizar elenco (Ano: #{year}): #{e.message}")
      { success: false, error: e.message }
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
            gols: p['goals'] || 0
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
                gols: p['goals'] || 0
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
  end
end
