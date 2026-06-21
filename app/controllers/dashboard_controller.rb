class DashboardController < ApplicationController
  include JogosHelper

  before_action :authenticate_user!
  before_action :authorize_root!, only: [:convites_pendentes, :aceitar_convite, :negar_convite, :new_user, :create_user, :editar_numeracao_selecoes, :editar_numeracao_jogadores, :salvar_numeracao_jogadores, :detalhamento_jogos]
  before_action :authorize_premium_or_admin!, only: [:artilharia]

  def index 
    if current_user.semi_root?
      @jogos_em_andamento = Jogo.em_andamento.order(data: :asc)
      @jogos_de_hoje = Jogo.programado
                            .where(definir: false)
                            .where(data: Time.current.beginning_of_day..Time.current.end_of_day)
                            .order(data: :asc)
      return render :semi_root_index
    end

    if current_user.root?
      @total_usuarios = User.count
      @usuarios_online = User.where('last_seen_at > ?', 5.minutes.ago).order(last_seen_at: :desc)
      @total_online = @usuarios_online.count
      @total_palpites = Palpite.count
      @total_premium = User.joins(:assinatura).where(assinaturas: { plano: :premium, ativa: true }).count
      @total_jogos = Jogo.count
      @total_ligas = Liga.count
      @ultimos_usuarios = User.includes(:palpites).order(created_at: :desc).limit(5)
      @jogos_em_andamento = Jogo.em_andamento.order(data: :asc).limit(10)
      @jogos_programados = Jogo.programado
                                .where(definir: false)
                                .where(data: Time.current.beginning_of_day..Time.current.end_of_day)
                                .order(data: :asc)
      @next_jogo_rapido = next_jogo_rapido(current_user)
      @jogos_pendentes = jogos_pendentes_count(current_user)
      return render :root_index
    end
    @next_jogo_rapido = next_jogo_rapido(current_user)
    @jogos_pendentes = jogos_pendentes_count(current_user)
    @ligas_ativas = current_user.liga_membros.where(status: :accepted).count
    hoje = Time.zone.today
    periodo_hoje = hoje.beginning_of_day..hoje.end_of_day
    @jogos_de_hoje = Jogo
      .includes(:mandante, :visitante, :palpites)
      .where(status: :em_andamento)
      .or(
        Jogo.includes(:mandante, :visitante, :palpites)
            .where(status: [:programado, :finalizado], definir: false, data: periodo_hoje)
      )
      .order(Arel.sql("CASE jogos.status WHEN #{Jogo.statuses[:em_andamento]} THEN 0 WHEN #{Jogo.statuses[:programado]} THEN 1 ELSE 2 END"), :data)
    @palpites_por_jogo_id = current_user.palpites.where(jogo_id: @jogos_de_hoje.map(&:id)).index_by(&:jogo_id)
    @proximos_jogos = Jogo.where("data >= ?", Time.current).order(data: :asc).limit(5)
    
    @liga_principal = current_user.ligas_participadas.first
    if @liga_principal
      @ranking_liga = @liga_principal.liga_membros
                                     .includes(:user)
                                     .where(status: :accepted)
                                     .sort_by { |lm| -lm.pontos_na_liga }
                                     .first(5)
    end

    @ligas_publicas = Liga.where(publica: true).order(membros: :desc).limit(5)

    # Ranking Global para todos
    # Ranking Global com as regras oficiais (Pontos > Palpites > Antiguidade)
    todos_usuarios = User
                      .select("users.*,
                               COALESCE((SELECT SUM(up.pontos) FROM user_points up WHERE up.user_id = users.id), 0) AS total_pontos_ranking,
                               COALESCE((SELECT COUNT(*) FROM palpites p WHERE p.user_id = users.id), 0) AS total_palpites")
                      .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
                      .to_a

    @ranking_global = todos_usuarios.first(5)
    @user_global_rank = todos_usuarios.index(current_user) ? todos_usuarios.index(current_user) + 1 : "-"
  end

  def detalhamento_jogos
    # 1. Carregar apenas os jogos finalizados
    scope = Jogo.includes(:mandante, :visitante, :informacao_jogo).where(status: :finalizado)
    
    # 2. Carregar todos os jogadores agrupados por seleção para mapeamento eficiente
    jogadores_por_selecao = Jogador.all.group_by(&:selecao_id)
    
    # 3. Computar gols esperados da artilharia com base nos JSONs
    @gols_calculados = Hash.new(0)
    @warnings_mapeamento = Hash.new { |h, k| h[k] = [] }
    
    # Iteramos por TODOS os jogos finalizados do banco para ter uma artilharia 100% calculada
    # mesmo que o filtro por status restrinja @jogos que exibiremos na listagem
    Jogo.finalizado.includes(:mandante, :visitante, :informacao_jogo).each do |jogo|
      info = jogo.informacao_jogo
      next unless info && info.dados.present?
      
      dados = info.dados
      dados = JSON.parse(dados) if dados.is_a?(String)
      
      goals = Jogos::SyncSquads.deduplicate_goals(dados['goals'] || [])
      lineups = dados['lineups'] || {}
      
      goals.each do |g|
        scorer = g['scorer']
        team_side = g['team']
        next if scorer.blank? || !team_side.in?(%w[home away])
        
        # Ignorar own goals
        next if scorer.downcase =~ /\b(o\.?g\.?|own\s+goal)\b/ || g['type'] == 'own_goal' || g['type'] == 'own-goal'
        
        selecao_local = (team_side == 'home') ? jogo.mandante : jogo.visitante
        next unless selecao_local
        
        team_lineup = lineups[team_side] || []
        player_in_lineup = team_lineup.find { |p| Jogos::SyncSquads.names_match?(p['player'], scorer) }
        
        jogador_local = nil
        if player_in_lineup
          jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
          jogador_local = jogadores_selecao.find { |j| j.numero == player_in_lineup['number'] }
          jogador_local ||= jogadores_selecao.find { |j| Jogos::SyncSquads.names_match?(j.nome, player_in_lineup['player']) }
        else
          jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
          jogador_local = jogadores_selecao.find { |j| Jogos::SyncSquads.names_match?(j.nome, scorer) }
        end
        
        if jogador_local
          @gols_calculados[jogador_local.id] += 1
        else
          @warnings_mapeamento[jogo.id] << "Jogador '#{scorer}' não mapeado no elenco da seleção '#{selecao_local.nome}'"
        end
      end
    end
    
    # 4. Identificar quais jogadores no banco têm discrepância de gols em relação aos gols calculados
    @jogadores_discrepantes = Jogador.all.select { |j| j.gols.to_i != @gols_calculados[j.id] }
    ids_jogadores_discrepantes = @jogadores_discrepantes.map(&:id).to_set
    
    # 5. Construir o diagnóstico para cada jogo no escopo filtrado
    @diagnostico_jogos = {}
    
    scope.each do |jogo|
      diag = {
        sincronizado: false,
        placar_bate: false,
        placar_api: nil,
        artilharia_ok: false,
        erros: []
      }
      
      # Para jogos que ainda não estão finalizados/em andamento, não exigimos sincronização nem artilharia
      if jogo.programado? || jogo.times_a_definir?
        diag[:sincronizado] = true
        diag[:placar_bate] = true
        diag[:artilharia_ok] = true
        @diagnostico_jogos[jogo.id] = diag
        next
      end
      
      info = jogo.informacao_jogo
      if info.nil? || info.dados.blank?
        diag[:erros] << "Estatísticas não sincronizadas"
        @diagnostico_jogos[jogo.id] = diag
        next
      end
      
      diag[:sincronizado] = true
      
      dados = info.dados
      dados = JSON.parse(dados) if dados.is_a?(String)
      
      goals = Jogos::SyncSquads.deduplicate_goals(dados['goals'] || [])
      lineups = dados['lineups'] || {}
      
      # Placar API (descartando gols contra provisórios do time que cometeu o gol contra)
      gols_home_api = goals.count { |g| g['team'] == 'home' && !(g['type'] == 'own_goal' && g['provisional'] == true) }
      gols_away_api = goals.count { |g| g['team'] == 'away' && !(g['type'] == 'own_goal' && g['provisional'] == true) }
      diag[:placar_api] = "#{gols_home_api} x #{gols_away_api}"
      
      if jogo.gols_mandante.to_i == gols_home_api && jogo.gols_visitante.to_i == gols_away_api
        diag[:placar_bate] = true
      else
        diag[:erros] << "Divergência no Placar: Banco tem #{jogo.gols_mandante}x#{jogo.gols_visitante}, API trouxe #{gols_home_api}x#{gols_away_api}"
      end
      
      # Artilharia OK?
      warnings = @warnings_mapeamento[jogo.id] || []
      
      # Verifica se há jogadores com discrepância que marcaram gol nesta partida
      jogadores_do_jogo_com_discrepancia = []
      
      goals.each do |g|
        scorer = g['scorer']
        team_side = g['team']
        next if scorer.blank? || !team_side.in?(%w[home away])
        next if scorer.downcase =~ /\b(o\.?g\.?|own\s+goal)\b/ || g['type'] == 'own_goal' || g['type'] == 'own-goal'
        
        selecao_local = (team_side == 'home') ? jogo.mandante : jogo.visitante
        next unless selecao_local
        
        team_lineup = lineups[team_side] || []
        player_in_lineup = team_lineup.find { |p| Jogos::SyncSquads.names_match?(p['player'], scorer) }
        
        jogador_local = nil
        if player_in_lineup
          jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
          jogador_local = jogadores_selecao.find { |j| j.numero == player_in_lineup['number'] }
          jogador_local ||= jogadores_selecao.find { |j| Jogos::SyncSquads.names_match?(j.nome, player_in_lineup['player']) }
        else
          jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
          jogador_local = jogadores_selecao.find { |j| Jogos::SyncSquads.names_match?(j.nome, scorer) }
        end
        
        if jogador_local && ids_jogadores_discrepantes.include?(jogador_local.id)
          jogadores_do_jogo_com_discrepancia << jogador_local
        end
      end
      
      if warnings.empty? && jogadores_do_jogo_com_discrepancia.empty?
        diag[:artilharia_ok] = true
      else
        warnings.each { |w| diag[:erros] << w }
        jogadores_do_jogo_com_discrepancia.uniq.each do |j|
          diag[:erros] << "Jogador '#{j.nome}' tem divergência global na artilharia: Banco=#{j.gols.to_i}, Calculado pelas Partidas=#{@gols_calculados[j.id]}"
        end
      end
      
      @diagnostico_jogos[jogo.id] = diag
    end
    
    # 6. Ordenação prioritária em Ruby:
    #    - Primeiro os finalizados por data decrescente (mais recentes primeiro).
    #    - Depois em_andamento e programados por data crescente (próximos a acontecer primeiro).
    jogos_finalizados = scope.select(&:finalizado?).sort_by(&:data).reverse
    jogos_futuros = scope.select { |j| j.programado? || j.em_andamento? }.sort_by(&:data)
    @jogos = jogos_finalizados + jogos_futuros
    
    # 7. Filtro por discrepância de dados (em Ruby pós-computação)
    if params[:com_diferenca] == "true"
      @jogos = @jogos.select do |jogo|
        diag = @diagnostico_jogos[jogo.id]
        diag && (!diag[:sincronizado] || !diag[:placar_bate] || !diag[:artilharia_ok])
      end
    end
    
    # 8. Métricas Gerais para o Painel Superior (baseado em todos os jogos finalizados no banco)
    jogos_totais_validos = Jogo.where(status: :finalizado)
    @total_jogos_validos = jogos_totais_validos.count
    @total_sincronizados = Jogo.finalizado.joins(:informacao_jogo).where.not(informacao_jogos: { dados: nil }).select { |j| j.informacao_jogo.dados.present? && j.informacao_jogo.dados != '{}' }.count
    
    # Precisamos recalcular os totais de divergência para exibir nos cards gerais corretamente
    @total_placar_correto = 0
    @total_artilharia_correta = 0
    
    # Executa verificação rápida e simplificada de integridade de placar/artilharia para todos os válidos
    jogos_totais_validos.each do |j|
      if j.programado?
        @total_placar_correto += 1
        @total_artilharia_correta += 1
        next
      end
      
      d = @diagnostico_jogos[j.id]
      if d
        @total_placar_correto += 1 if d[:sincronizado] && d[:placar_bate]
        @total_artilharia_correta += 1 if d[:sincronizado] && d[:artilharia_ok]
      else
        # Se não carregou no escopo filtrado, checa separadamente
        info = j.informacao_jogo
        if info && info.dados.present?
          begin
            dados = info.dados
            dados = JSON.parse(dados) if dados.is_a?(String)
            goals = Jogos::SyncSquads.deduplicate_goals(dados['goals'] || [])
            gols_h = goals.count { |g| g['team'] == 'home' && !(g['type'] == 'own_goal' && g['provisional'] == true) }
            gols_a = goals.count { |g| g['team'] == 'away' && !(g['type'] == 'own_goal' && g['provisional'] == true) }
            
            placar_ok = (j.gols_mandante.to_i == gols_h && j.gols_visitante.to_i == gols_a)
            @total_placar_correto += 1 if placar_ok
            
            # Artilharia simplificada
            art_ok = true
            warnings = @warnings_mapeamento[j.id] || []
            if warnings.any?
              art_ok = false
            else
              goals.each do |g|
                scorer = g['scorer']
                team_side = g['team']
                next if scorer.blank? || !team_side.in?(%w[home away])
                next if scorer.downcase =~ /\b(o\.?g\.?|own\s+goal)\b/ || g['type'] == 'own_goal' || g['type'] == 'own-goal'
                
                selecao_local = (team_side == 'home') ? j.mandante : j.visitante
                next unless selecao_local
                
                team_lineup = (dados['lineups'] || {})[team_side] || []
                player_in_lineup = team_lineup.find { |p| Jogos::SyncSquads.names_match?(p['player'], scorer) }
                
                jogador_local = nil
                if player_in_lineup
                  jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
                  jogador_local = jogadores_selecao.find { |j_loc| j_loc.numero == player_in_lineup['number'] }
                  jogador_local ||= jogadores_selecao.find { |j_loc| Jogos::SyncSquads.names_match?(j_loc.nome, player_in_lineup['player']) }
                else
                  jogadores_selecao = jogadores_por_selecao[selecao_local.id] || []
                  jogador_local = jogadores_selecao.find { |j_loc| Jogos::SyncSquads.names_match?(j_loc.nome, scorer) }
                end
                
                if !jogador_local || ids_jogadores_discrepantes.include?(jogador_local.id)
                  art_ok = false
                  break
                end
              end
            end
            @total_artilharia_correta += 1 if art_ok
          rescue
            # ignorar falhas silenciosas
          end
        end
      end
    end
    
    @total_gols_artilharia_banco = Jogador.sum(:gols)
    @total_gols_artilharia_calculado = @gols_calculados.values.sum
  end

  def convites_pendentes
    @convites = LigaMembro.invited.includes(:user, liga: :owner).order(created_at: :desc)
  end

  def aceitar_convite
    liga_membro = LigaMembro.find_by_uuid_param!(params[:liga_membro_id])
    
    ActiveRecord::Base.transaction do
      liga_membro.update!(status: :accepted)
      liga_membro.liga.increment!(:membros)
      liga_membro.user.count_referral_for_liga!(liga_membro.liga)
    end

    redirect_to dashboard_convites_pendentes_path, notice: "Solicitação do usuário #{liga_membro.user.name} para entrar na liga '#{liga_membro.liga.nome}' aceita com sucesso!"
  end

  def negar_convite
    liga_membro = LigaMembro.find_by_uuid_param!(params[:liga_membro_id])
    user_name = liga_membro.user.name
    liga_nome = liga_membro.liga.nome
    liga_membro.destroy!

    redirect_to dashboard_convites_pendentes_path, notice: "Solicitação do usuário #{user_name} para entrar na liga '#{liga_nome}' rejeitada com sucesso."
  end

  def new_user
    @usuario = User.new(tipo: :root)
  end

  def create_user
    @usuario = User.new(user_create_params)
    
    temp_password = SecureRandom.alphanumeric(12) + "aA1!"
    @usuario.password = temp_password
    @usuario.password_confirmation = temp_password
    @usuario.selecao_id = Selecao.find_by(nome: 'A definir')&.id || Selecao.first&.id
    @usuario.tipo = :semi_root
    @usuario.terms_of_service = '1'
    @usuario.esconder_odds = false

    @usuario.skip_confirmation!

    if @usuario.save
      redirect_to authenticated_root_path, notice: "Usuário Operador (Semi-Root) criado com sucesso! E-mail: #{@usuario.email} | Senha temporária: #{temp_password}"
    else
      flash.now[:alert] = "Erro ao criar usuário: #{@usuario.errors.full_messages.to_sentence}"
      render :new_user, status: :unprocessable_entity
    end
  end

  def artilharia
    @artilheiros = Jogador.includes(:selecao)
                          .joins(:selecao)
                          .where("jogadores.gols > 0")
                          .order("jogadores.gols DESC, selecoes.qtd_jogos ASC, jogadores.nome ASC")
  end

  def editar_numeracao_selecoes
    @selecoes = Selecao.joins(:jogadores)
                       .where(jogadores: { numero: nil })
                       .distinct
                       .order(:nome)
  end

  def editar_numeracao_jogadores
    @selecao = Selecao.find_by_uuid_param!(params[:selecao_id])
    @jogadores = @selecao.jogadores.order(:nome)
  end

  def salvar_numeracao_jogadores
    @selecao = Selecao.find_by_uuid_param!(params[:selecao_id])
    
    if params[:jogadores].present?
      errors = []
      Jogador.transaction do
        params[:jogadores].each do |jogador_id, jogador_params|
          jogador = @selecao.jogadores.find_by(id: jogador_id)
          if jogador
            update_attrs = {
              numero: jogador_params[:numero].presence,
              nome: jogador_params[:nome].presence || jogador.nome,
              capitao: jogador_params[:capitao] == '1',
              clube: jogador_params[:clube].presence,
              clube_pais: jogador_params[:clube_pais].presence
            }
            unless jogador.update(update_attrs)
              errors << "Erro ao salvar #{jogador.nome}: #{jogador.errors.full_messages.to_sentence}"
            end
          end
        end
        raise ActiveRecord::Rollback if errors.any?
      end

      if errors.any?
        redirect_to dashboard_editar_numeracao_jogadores_path(@selecao), alert: "Erro ao atualizar numeração: #{errors.join(', ')}"
      else
        redirect_to dashboard_editar_numeracao_selecoes_path, notice: "Numeração dos jogadores da seleção #{@selecao.nome} atualizada com sucesso!"
      end
    else
      redirect_to dashboard_editar_numeracao_selecoes_path, alert: "Nenhum jogador informado para atualização."
    end
  end

  private

  def authorize_premium_or_admin!
    return if current_user.root? || current_user.semi_root?
    return if current_user.premium? && current_user.assinatura&.ativa?

    redirect_to authenticated_root_path, alert: "A tela de artilharia é exclusiva para assinantes Premium!"
  end

  def user_create_params
    params.require(:user).permit(:name, :email)
  end
end
