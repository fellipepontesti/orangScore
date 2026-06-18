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

      api_home_name = Jogos::TeamMapping.api_search_name(jogo.mandante.nome)
      api_away_name = Jogos::TeamMapping.api_search_name(jogo.visitante.nome)

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
        (m['homeTeam'].to_s.downcase == api_home_name.downcase && m['awayTeam'].to_s.downcase == api_away_name.downcase) ||
        (m['homeTeam'].to_s.downcase == api_away_name.downcase && m['awayTeam'].to_s.downcase == api_home_name.downcase)
      end

      unless api_match
        return { success: false, error: "Partida correspondente não encontrada na API." }
      end

      stats = api_match['statistics']
      if stats.blank?
        return { success: false, error: "Estatísticas ainda não disponíveis para esta partida na API." }
      end

      info = Jogo.transaction do
        info_local = jogo.informacao_jogo || JogoInformacaoWrapper.get_or_build(jogo)
        info_local.dados = stats
        info_local.save!
        info_local
      end

      { success: true, stats: stats }
    rescue => e
      Rails.logger.error("Erro ao sincronizar estatísticas do jogo #{jogo.id}: #{e.message}")
      { success: false, error: e.message }
    end
  end
end

class JogoInformacaoWrapper
  def self.get_or_build(jogo)
    InformacaoJogo.find_by(jogo_id: jogo.id) || InformacaoJogo.new(jogo_id: jogo.id)
  end
end
