require 'net/http'
require 'json'
require 'uri'

module ApiFootballTeams
  class Sync
    # League ID 1 = World Cup, Season 2026
    WORLD_CUP_LEAGUE = 1
    WORLD_CUP_SEASON = 2026

    def initialize
      @api_key = ENV['API_FOOTBALL_KEY']
      @base_url = 'https://v3.football.api-sports.io'
      @report = { created: [], updated: [], skipped: [], errors: [] }
      @processed_team_ids = Set.new
    end

    def call
      raise 'Chave API_FOOTBALL_KEY não definida.' if @api_key.blank?

      # Buscar todos os fixtures da Copa do Mundo 2026
      fetch_and_import_teams_from_fixtures

      @report
    end

    private

    def fetch_and_import_teams_from_fixtures
      page = 1
      loop do
        response = request("/fixtures?league=#{WORLD_CUP_LEAGUE}&season=#{WORLD_CUP_SEASON}&page=#{page}")
        
        break if response.nil? || response['response'].blank?

        response['response'].each do |fixture|
          import_team_from_fixture(fixture, 'home')
          import_team_from_fixture(fixture, 'away')
        end

        # Verificar se há mais páginas
        paging = response.dig('paging')
        break if paging.nil? || page >= paging['total']

        page += 1
      end
    end

    def import_team_from_fixture(fixture, side)
      team_data = fixture.dig('teams', side)
      return unless team_data

      api_id = team_data.dig('id')
      return if api_id.nil? || @processed_team_ids.include?(api_id)

      @processed_team_ids.add(api_id)

      api_team = ApiFootballTeam.find_or_initialize_by(api_id: api_id)
      new_record = api_team.new_record?

      api_team.name = team_data.dig('name')
      api_team.country = team_data.dig('country')
      api_team.code = team_data.dig('code')
      api_team.logo = team_data.dig('logo')

      if api_team.save
        @report[new_record ? :created : :updated] << api_team
      else
        @report[:errors] << { api_id: api_id, name: team_data.dig('name'), errors: api_team.errors.full_messages }
      end
    rescue => e
      @report[:errors] << { error: e.message, fixture: fixture }
    end

    def request(endpoint)
      uri = URI("#{@base_url}#{endpoint}")
      req = Net::HTTP::Get.new(uri)
      req['x-apisports-key'] = @api_key

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      return nil unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error("Erro ao fazer requisição para API Football: #{e.message}")
      nil
    end
  end
end
