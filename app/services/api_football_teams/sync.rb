require 'net/http'
require 'json'
require 'uri'

module ApiFootballTeams
  class Sync
    def initialize
      @api_key = ENV['API_FOOTBALL_KEY']
      @base_url = 'https://v3.football.api-sports.io'
      @report = { created: [], updated: [], skipped: [], errors: [] }
    end

    def call
      raise 'Chave API_FOOTBALL_KEY não definida.' if @api_key.blank?

      team_names.each do |search_name|
        import_team(search_name)
      end

      @report
    end

    private

    def team_names
      Jogos::TeamMapping::WORLD_CUP_TEAM_SEARCH.values.uniq.sort
    end

    def import_team(search_name)
      response = request("/teams?search=#{URI.encode_www_form_component(search_name)}&season=2026")
      if response.nil? || response['response'].blank?
        @report[:skipped] << { name: search_name, reason: 'Sem resposta da API' }
        return
      end

      team_data = find_best_team(response['response'], search_name)
      unless team_data
        @report[:skipped] << { name: search_name, reason: 'Nenhum time compatível encontrado' }
        return
      end

      api_team = ApiFootballTeam.find_or_initialize_by(api_id: team_data.dig('team', 'id'))
      new_record = api_team.new_record?

      api_team.name = team_data.dig('team', 'name')
      api_team.country = team_data.dig('team', 'country')
      api_team.code = team_data.dig('team', 'code')
      api_team.logo = team_data.dig('team', 'logo')
      api_team.founded = team_data.dig('team', 'founded')
      api_team.city = team_data.dig('venue', 'city')

      if api_team.save
        @report[new_record ? :created : :updated] << api_team
      else
        @report[:errors] << { name: search_name, errors: api_team.errors.full_messages }
      end
    rescue => e
      @report[:errors] << { name: search_name, error: e.message }
    end

    def find_best_team(response_items, search_name)
      normalized_search = search_name.to_s.downcase.strip
      exact_match = response_items.find do |item|
        team_name = item.dig('team', 'name').to_s.downcase
        team_country = item.dig('team', 'country').to_s.downcase

        team_name == normalized_search || team_country == normalized_search
      end

      exact_match || response_items.first
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
    end
  end
end
