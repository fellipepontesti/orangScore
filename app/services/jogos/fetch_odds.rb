require 'net/http'
require 'json'
require 'uri'

module Jogos
  class FetchOdds
    def initialize(jogo:)
      @jogo = jogo
      @api_key = ENV['API_FOOTBALL_KEY']
      @base_url = 'https://v3.football.api-sports.io'
    end

    def call
      # Se as odds já estão salvas, não chama a API novamente
      return if @jogo.prob_mandante.present? && @jogo.prob_visitante.present?

      # Tenta buscar a odd real pela API
      odds = fetch_from_api_if_possible

      if odds
        @jogo.update_columns(
          prob_mandante: odds[:home],
          prob_empate: odds[:draw],
          prob_visitante: odds[:away]
        )
      else
        # Fallback inteligente (se estourou limite da API ou o jogo é customizado e não existe na API)
        calculate_fallback_odds
      end
    end

    private

    def fetch_from_api_if_possible
      return nil if @api_key.blank? || !@jogo.mandante || !@jogo.visitante

      mandante_nome = @jogo.mandante.nome
      visitante_nome = @jogo.visitante.nome

      # 1. Tentar encontrar os IDs dos times na API
      team_home_id = search_team_id(mandante_nome)
      team_away_id = search_team_id(visitante_nome)

      return nil unless team_home_id && team_away_id

      # 2. Buscar o head-to-head ou próximo jogo entre eles
      fixture_id = find_fixture_id(team_home_id, team_away_id)
      return nil unless fixture_id

      # 3. Buscar a "Prediction" para extrair a porcentagem
      get_prediction(fixture_id)
    rescue => e
      Rails.logger.error "Erro na API-Football: #{e.message}"
      nil
    end

    def search_team_id(name)
      return nil if name.blank?

      normalized = name.strip
      [normalized, normalized.split.first].each do |query|
        next if query.blank?

        response = request("/teams?search=#{URI.encode_www_form_component(query)}")
        next unless response && response['response'].present?

        match = response['response'].find do |item|
          api_name = item.dig('team', 'name').to_s.downcase
          api_name == normalized.downcase || api_name.include?(normalized.downcase)
        end

        match ||= response['response'].first
        return match.dig('team', 'id') if match
      end

      nil
    end

    def find_fixture_id(home_id, away_id)
      date = @jogo.data&.strftime('%Y-%m-%d')

      if date.present?
        response = request("/fixtures?date=#{date}&team=#{home_id}")
        fixture = find_matching_fixture(response, home_id, away_id)
        return fixture.dig('fixture', 'id') if fixture

        response = request("/fixtures?date=#{date}&team=#{away_id}")
        fixture = find_matching_fixture(response, home_id, away_id)
        return fixture.dig('fixture', 'id') if fixture
      end

      response = request("/fixtures?h2h=#{home_id}-#{away_id}&next=1")
      fixture = response['response']&.first if response && response['response'].present?
      return fixture.dig('fixture', 'id') if fixture

      response = request("/fixtures?h2h=#{home_id}-#{away_id}&last=1")
      fixture = response['response']&.first if response && response['response'].present?
      fixture&.dig('fixture', 'id')
    end

    def find_matching_fixture(response, home_id, away_id)
      return nil unless response && response['response'].present?

      response['response'].find do |item|
        [item.dig('teams', 'home', 'id'), item.dig('teams', 'away', 'id')].sort == [home_id, away_id].sort
      end
    end

    def get_prediction(fixture_id)
      response = request("/predictions?fixture=#{fixture_id}")
      return nil if response.nil? || response['response'].empty?

      prediction = response['response'].first.dig('predictions')
      prediction = prediction.first if prediction.is_a?(Array)
      percent = prediction&.dig('percent')
      return nil unless percent

      {
        home: percent['home'].to_i,
        draw: percent['draw'].to_i,
        away: percent['away'].to_i
      }
    end

    def request(endpoint)
      uri = URI("#{@base_url}#{endpoint}")
      req = Net::HTTP::Get.new(uri)
      req['x-apisports-key'] = @api_key

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      return nil unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    end

    def calculate_fallback_odds
      # Base de cálculo para fallback quando a API não encontra times fictícios/customizados
      # Usa a pontuação e vitórias atuais do sistema
      hm = @jogo.mandante
      aw = @jogo.visitante
      
      return unless hm && aw

      # Força = Pontos + (Vitórias * 2) + Gols
      f_home = (hm.pontos || 0) + ((hm.vitorias || 0) * 2) + (hm.gols || 0)
      f_away = (aw.pontos || 0) + ((aw.vitorias || 0) * 2) + (aw.gols || 0)
      
      if f_home == 0 && f_away == 0
        @jogo.update_columns(prob_mandante: 40, prob_empate: 20, prob_visitante: 40)
        return
      end

      f_draw = ((hm.empates || 0) + (aw.empates || 0)) * 2 + 5
      f_draw = 1 if f_draw == 0

      total = (f_home + f_away + f_draw).to_f
      
      p_home = ((f_home / total) * 100).round
      p_away = ((f_away / total) * 100).round
      p_draw = 100 - p_home - p_away # Garantir soma de 100%

      @jogo.update_columns(
        prob_mandante: p_home,
        prob_empate: p_draw,
        prob_visitante: p_away
      )
    end
  end
end
