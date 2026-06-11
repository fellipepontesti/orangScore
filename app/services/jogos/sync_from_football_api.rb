require 'net/http'
require 'json'
require 'uri'

module Jogos
  class SyncFromFootballApi
    attr_reader :api_key, :base_url

    def initialize
      @api_key = ENV['API_FOOTBALL_KEY']
      @base_url = 'https://v3.football.api-sports.io'
      @report = {
        updated: [],
        skipped: [],
        errors: [],
        scorers: Hash.new(0),
        assists: Hash.new(0)
      }
    end

    def call
      return @report.merge(error: 'Chave API_FOOTBALL_KEY não configurada') if api_key.blank?

      Jogo.where.not(status: :finalizado).find_each do |jogo|
        sync_jogo(jogo)
      end

      @report
    end

    private

    def sync_jogo(jogo)
      return @report[:skipped] << { jogo: jogo, reason: 'Times ou data incompletos' } unless jogo.mandante && jogo.visitante && jogo.data

      fixture = find_api_fixture(jogo)
      return @report[:skipped] << { jogo: jogo, reason: 'Partida não encontrada na API' } unless fixture

      api_status = fixture.dig('fixture', 'status', 'short')
      home_goals = fixture.dig('goals', 'home')
      away_goals = fixture.dig('goals', 'away')
      new_status = map_api_status(api_status)

      previous_status = jogo.status
      changes = {}
      changes[:status] = new_status if new_status && new_status != jogo.status
      changes[:gols_mandante] = home_goals unless home_goals.nil?
      changes[:gols_visitante] = away_goals unless away_goals.nil?

      if changes.any?
        jogo.transaction do
          jogo.update!(changes)

          Jogos::StatusNotifier.new(jogo: jogo).call if jogo.saved_change_to_status?
          Jogos::CalculaPontuacao.new(jogo: jogo).call if jogo.finalizado? && jogo.saved_change_to_status?
        end
      end

      update_probabilities(jogo, fixture)
      collect_fixture_stats(fixture)

      @report[:updated] << {
        jogo: jogo,
        fixture_id: fixture.dig('fixture', 'id'),
        api_status: api_status,
        old_status: previous_status,
        new_status: jogo.status,
        gols_mandante: jogo.gols_mandante,
        gols_visitante: jogo.gols_visitante
      }
    rescue => e
      @report[:errors] << { jogo: jogo, message: e.message }
    end

    def find_api_fixture(jogo)
      home_id = search_team_id(jogo.mandante.nome)
      away_id = search_team_id(jogo.visitante.nome)
      return nil unless home_id && away_id

      date = jogo.data&.strftime('%Y-%m-%d')
      fixture = search_fixture_by_date(home_id, away_id, date) if date.present?
      fixture ||= search_fixture_by_h2h(home_id, away_id)
      fixture
    end

    def search_fixture_by_date(home_id, away_id, date)
      response = request("/fixtures?date=#{date}&team=#{home_id}")
      fixture = find_matching_fixture(response, home_id, away_id)
      return fixture if fixture

      response = request("/fixtures?date=#{date}&team=#{away_id}")
      find_matching_fixture(response, home_id, away_id)
    end

    def search_fixture_by_h2h(home_id, away_id)
      response = request("/fixtures?h2h=#{home_id}-#{away_id}&next=1")
      return response['response'].first if response && response['response'].present?

      response = request("/fixtures?h2h=#{home_id}-#{away_id}&last=1")
      response['response'].first if response && response['response'].present?
    end

    def find_matching_fixture(response, home_id, away_id)
      return nil unless response && response['response'].present?

      response['response'].find do |item|
        teams = [item.dig('teams', 'home', 'id'), item.dig('teams', 'away', 'id')].compact.map(&:to_i).sort
        [home_id, away_id].sort == teams
      end
    end

    def collect_fixture_stats(fixture)
      fixture_id = fixture.dig('fixture', 'id')
      response = request("/fixtures/events?fixture=#{fixture_id}")
      return unless response && response['response'].present?

      response['response'].each do |event|
        next if event.dig('type', 'name') != 'Goal'

        scorer = event.dig('player', 'name')
        assist = event.dig('assist', 'name')

        @report[:scorers][scorer] += 1 if scorer.present?
        @report[:assists][assist] += 1 if assist.present?
      end
    rescue => e
      Rails.logger.error("Erro ao buscar estatísticas de fixture #{fixture_id}: #{e.message}")
    end

    def search_team_id(name)
      return nil if name.blank?

      lookup_name = Jogos::TeamMapping.api_search_name(name)
      response = request("/teams?search=#{URI.encode_www_form_component(lookup_name)}")
      return nil unless response && response['response'].present?

      response['response'].first.dig('team', 'id')
    end

    def update_probabilities(jogo, fixture)
      fixture_id = fixture.dig('fixture', 'id')
      prediction = get_prediction(fixture_id)
      return unless prediction

      jogo.update_columns(
        prob_mandante: prediction[:home],
        prob_empate: prediction[:draw],
        prob_visitante: prediction[:away]
      )
    end

    def same_match_date?(fixture, local_date)
      api_date = fixture.dig('fixture', 'date')
      return false unless api_date

      fixture_time = Time.parse(api_date).utc
      local_time = local_date.utc
      fixture_time.to_date == local_time.to_date
    rescue
      false
    end

    def map_api_status(short)
      case short
      when 'NS', 'TBD'
        'programado'
      when '1H', '2H', 'HT', 'ET', 'LIVE'
        'em_andamento'
      when 'FT', 'AET', 'PEN'
        'finalizado'
      else
        'programado'
      end
    end

    def request(endpoint)
      uri = URI("#{base_url}#{endpoint}")
      req = Net::HTTP::Get.new(uri)
      req['x-apisports-key'] = api_key

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      return nil unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    rescue => e
      Rails.logger.error("Erro na API-Football: #{e.message}")
      nil
    end
  end
end
