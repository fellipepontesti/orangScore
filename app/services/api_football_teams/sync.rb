module ApiFootballTeams
  class Sync
    def initialize
      @report = { created: [], updated: [], skipped: [], errors: [] }
    end

    def call
      @report = { created: [], updated: [], skipped: [], errors: [] }

      selecao = next_pending_selection

      unless selecao
        @report[:skipped] << { name: nil, reason: "Todas as seleções já estão na tabela API Football." }
        return @report
      end

      result = sync_team(selecao.nome)
      if result[:success]
        status_key = result[:new_record] ? :created : :updated
        @report[status_key] << result[:api_team]
      elsif result[:skipped]
        @report[:skipped] << { name: selecao.nome, reason: result[:reason] }
      else
        @report[:errors] << { name: selecao.nome, error: result[:error] }
      end

      @report
    end

    def sync_next_pending_team
      selecao = next_pending_selection
      return { skipped: true, reason: "Todas as seleções já estão na tabela API Football." } unless selecao

      result = sync_team(selecao.nome)
      result.merge(selecao: selecao)
    end

    def next_pending_selection
      Selecao
        .where.not(nome: ['A definir', 'Provisório'])
        .where.not(id: ApiFootballTeam.where.not(selecao_id: nil).select(:selecao_id))
        .order(:nome)
        .first
    end

    def sync_team(nome_selecao)
      selecao = Selecao.find_by(nome: nome_selecao)
      return { error: "Seleção local '#{nome_selecao}' não encontrada no banco" } unless selecao

      if ApiFootballTeam.exists?(selecao_id: selecao.id)
        return { skipped: true, reason: "Seleção '#{nome_selecao}' já existe na tabela API Football." }
      end

      team_code = Jogos::TeamMapping.api_team_code(nome_selecao)
      if team_code.nil? || team_code.to_s.strip.empty?
        return { error: "Código FIFA não mapeado para #{nome_selecao}" }
      end

      Rails.logger.info("[API FOOTBALL] Buscando seleção nacional por code: '#{team_code}'")
      response = ApiFootballClient.request("/teams?code=#{team_code}")
      team_data = find_national_team(response)

      return { error: "Nenhuma seleção nacional encontrada na API para o código '#{team_code}'" } if team_data.nil?

      api_id = team_data.dig('id')
      return { error: "ID da API ausente para o código #{team_code}" } if api_id.nil?

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
