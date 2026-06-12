require 'uri'

module ApiFootballTeams
  class Sync
    def initialize
      @report = { created: [], updated: [], skipped: [], errors: [] }
    end

    # Método principal para sincronizar todas as seleções (mantém assinatura call)
    def call
      @report = { created: [], updated: [], skipped: [], errors: [] }
      
      # Sincronizar todas as seleções cadastradas (exceto as provisórias)
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
        
        # Respeita o limite de requisições dando um pequeno intervalo
        sleep 0.2
      end

      @report
    end

    # Sincroniza uma seleção específica pelo nome
    def sync_team(nome_selecao)
      # 1. Traduz o nome da seleção para inglês usando o TeamMapping
      lookup_name = Jogos::TeamMapping.api_search_name(nome_selecao)
      return { error: "Nome de busca não mapeado para #{nome_selecao}" } if lookup_name.blank?

      # 2. Faz a chamada à API Football usando /teams?name=lookup_name
      response = ApiFootballClient.request("/teams?name=#{URI.encode_www_form_component(lookup_name)}")
      
      # Se não encontrar por name, tenta por search
      if response.nil? || response['response'].blank?
        response = ApiFootballClient.request("/teams?search=#{URI.encode_www_form_component(lookup_name)}")
      end

      return { error: "Nenhum dado retornado da API para #{lookup_name}" } if response.nil? || response['response'].blank?

      # 3. Pega os dados do primeiro time retornado
      team_data = response['response'].first.dig('team')
      return { error: "Formato inválido de dados do time na resposta da API" } unless team_data

      api_id = team_data.dig('id')
      return { error: "ID da API ausente para o time #{lookup_name}" } if api_id.nil?

      # 4. Encontra a seleção local no sistema pelo nome
      selecao = Selecao.find_by(nome: nome_selecao)
      return { error: "Seleção local '#{nome_selecao}' não encontrada no banco de dados" } unless selecao

      # 5. Salva ou atualiza a associação na tabela ApiFootballTeam
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
  end
end
