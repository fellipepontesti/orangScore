require 'uri'

module ApiFootballTeams
  class Sync
    def initialize
      @report = { created: [], updated: [], skipped: [], errors: [] }
    end

    def call
      @report = { created: [], updated: [], skipped: [], errors: [] }
      
      Selecao.where.not(nome: ['A definir', 'Provisório']).each do |selecao|
        result = sync_team(selecao.nome)
        if result[:success]
          status_key = result[:new_record] ? :created : :updated
          @report[status_key] << result[:api_team]
        elsif result[:skipped]
          @report[:skipped] << { name: selecao.nome, reason: result[:reason] }
        else
          @report[:errors] << { name: selecao.nome, error: result[:error] }
        end
        
        # Rate limit preventivo
        sleep 7
      end

      @report
    end

    def sync_team(nome_selecao)
      lookup_name = Jogos::TeamMapping.api_search_name(nome_selecao)
      if lookup_name.nil? || lookup_name.to_s.strip.empty?
        return { error: "Nome de busca não mapeado para #{nome_selecao}" }
      end

      # Log de depuração para acompanhar no console do Rails
      Rails.logger.info("[API FOOTBALL] Buscando seleção nacional por name: '#{lookup_name}'")

      # 1. Tenta buscar pelo parâmetro oficial ?name=
      response = ApiFootballClient.request("/teams?name=#{URI.encode_www_form_component(lookup_name)}")
      team_data = find_national_team(response)

      # 2. Fallback por ?search= caso o name estrito falhe
      if team_data.nil?
        Rails.logger.warn("[API FOOTBALL] Não encontrado por 'name', tentando por 'search': '#{lookup_name}'")
        response = ApiFootballClient.request("/teams?search=#{URI.encode_www_form_component(lookup_name)}")
        team_data = find_national_team(response)
      end

      return { error: "Nenhuma seleção nacional encontrada na API para '#{lookup_name}'" } if team_data.nil?

      api_id = team_data.dig('id')
      return { error: "ID da API ausente para o time #{lookup_name}" } if api_id.nil?

      selecao = Selecao.find_by(nome: nome_selecao)
      return { error: "Seleção local '#{nome_selecao}' não encontrada no banco" } unless selecao

      # Salva ou atualiza
      api_team = ApiFootballTeam.find_or_initialize_by(api_id: api_id)
      new_record = api_team.new_record?

      api_team.name = team_data.dig('name')
      api_team.country = team_data.dig('country')
      api_team.code = team_data.dig('code')
      api_team.logo = team_data.dig('logo')
      api_team.selecao = selecao

      if api_team.save
        { success: true, api_team: api_team, new_record: new_record }
      else
        { error: "Erro ao salvar ApiFootballTeam: #{api_team.errors.full_messages.to_sentence}" }
      end
    rescue => e
      Rails.logger.error("Erro na sincronização de #{nome_selecao}: #{e.message}")
      { error: e.message }
    end

    private

    def find_national_team(response)
      return nil if response.nil? || response['response'].blank?

      # Garante a captura avaliando o booleano de forma segura
      national_item = response['response'].find do |item| 
        item.dig('team', 'national') == true
      end
      
      national_item&.dig('team')
    end
  end
end