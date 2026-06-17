require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncSquads
    attr_reader :selecao, :api_name, :year, :api_key

    def initialize(selecao:, api_name:, year: '2026')
      @selecao = selecao
      @api_name = api_name.to_s.strip
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

      # Buscar a seleção correspondente no JSON retornado
      team_data = data['teams'].find do |t|
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
        # Limpar elenco atual para a seleção no sistema
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
            clube_pais: p.dig('club', 'country'),
            capitao: p['captain'] || false,
            gols: p['goals'] || 0
          )
          players_imported += 1
        end
      end

      { success: true, count: players_imported }
    rescue => e
      Rails.logger.error("Erro ao sincronizar elenco da seleção #{selecao.nome}: #{e.message}")
      { success: false, error: e.message }
    end
  end
end
