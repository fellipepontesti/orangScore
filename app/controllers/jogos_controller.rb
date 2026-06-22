class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy start finalize finish sync_statistics palpites remove_goal update_goal ]
  before_action :load_selecoes, only: %i[new create edit update finalize]
  before_action :authorize_root_or_semi_root!, only: %i[start update finish sync_statistics]
  before_action :authorize_root!, except: %i[index show start update finish sync_statistics palpites]

  def index
    filtro_por_data = params[:data].present? || params[:start_date].present? || params[:end_date].present?
    @tipo_ativo = params[:tipo].presence
    @tipo_ativo ||= 'grupo' unless filtro_por_data
    @grupos = Grupo.order(:nome)

    @grupo_ativo = if @tipo_ativo == 'grupo'
      params[:grupo].presence || @grupos.first&.uuid
    end
    
    @status_filtro = params[:status]
    @data_inicio = params[:start_date].presence || params[:data]
    @data_fim = params[:end_date].presence || params[:data]

    @jogos = Jogos::List.new(params: {
      tipo: @tipo_ativo,
      grupo: @grupo_ativo,
      status: @status_filtro,
      start_date: @data_inicio,
      end_date: @data_fim
    }).call
  end

  def show
    @palpite = current_user.palpites.find_by(jogo_id: @jogo.id)
    @user_point = current_user.user_points.find_by(jogo_id: @jogo.id)
  end

  def palpites
    if @jogo.programado? && !current_user.root?
      redirect_to @jogo, alert: "Os palpites só estarão visíveis após o início da partida."
      return
    end

    @palpites = @jogo.palpites.includes(:user).to_a
    @user_points_by_user = @jogo.user_points.index_by(&:user_id)

    @pontos_por_palpite = {}
    @palpites.each do |p|
      pontos = if @jogo.finalizado? && @user_points_by_user[p.user_id]
        @user_points_by_user[p.user_id].pontos.to_i
      elsif @jogo.em_andamento? || @jogo.suspenso? || @jogo.finalizado?
        Jogos::CalculaPontuacao.calcular_pontos_em_memoria(p, @jogo.gols_mandante, @jogo.gols_visitante)
      else
        0
      end
      @pontos_por_palpite[p.id] = pontos
    end

    @palpites.sort_by! do |p|
      pontos = @pontos_por_palpite[p.id]
      [pontos, p.user.name.to_s.downcase]
    end

    @total_palpites = @palpites.size
    mais_comum = @palpites.map { |p| "#{p.gols_casa}x#{p.gols_fora}" }.tally.max_by { |_, count| count }
    @palpite_mais_comum = mais_comum ? mais_comum.first.gsub('x', ' - ') : "—"
    
    @media_gols_palpitados = if @palpites.any?
      (@palpites.sum { |p| p.gols_casa + p.gols_fora }.to_f / @total_palpites).round(1)
    else
      "—"
    end
  end

  def new
    @jogo = Jogo.new
    @selecoes = Selecao.order(:nome)
    @grupos = Grupo.order(:nome)
  end

  def edit
    @selecoes = Selecao.order(:nome)
    @grupos = Grupo.order(:nome)
  end

  def create
    @jogo = Jogos::Create.new(params: jogo_params).call

    respond_to do |format|
      if @jogo.persisted?
        format.html { redirect_to @jogo, notice: "Jogo criado com sucesso!." }
        format.json { render :show, status: :created, location: @jogo }
      else
        @selecoes = Selecao.order(:nome)
        @grupos = Grupo.order(:nome)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params).call

    respond_to do |format|
      if @jogo.errors.empty?
        format.html do
          if params[:redirect_to_dashboard] == 'true'
            redirect_to authenticated_root_path, notice: "Placar atualizado com sucesso!"
          else
            redirect_to @jogo, notice: "Jogo atualizado com sucesso!.", status: :see_other
          end
        end
        format.json { render :show, status: :ok, location: @jogo }
      else
        @selecoes = Selecao.order(:nome)
        @grupos = Grupo.order(:nome)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def start
    Jogos::Start.new(jogo: @jogo).call
    redirect_to @jogo, notice: "Jogo iniciado com sucesso! Notificações enviadas."
  rescue => e
    redirect_to @jogo, alert: e.message
  end

  def finalize
  end

  def finish
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params.merge(status: 'finalizado')).call

    if @jogo.errors.empty?
      # Tenta sincronizar as estatísticas reais de chutes/posse da partida na API Zafronix
      Jogos::SyncMatchStatistics.new(jogo: @jogo).call rescue nil

      redirect_to @jogo, notice: "Jogo finalizado com sucesso! Pontuações calculadas."
    else
      render :finalize, status: :unprocessable_entity
    end
  end

  def sync_statistics
    result = Jogos::SyncMatchStatistics.new(jogo: @jogo).call

    if current_user.root?
      texto = if result[:success]
        "Sincronização de estatísticas do jogo #{@jogo.mandante&.nome} x #{@jogo.visitante&.nome} concluída com sucesso!"
      else
        "Sincronização de estatísticas do jogo #{@jogo.mandante&.nome} x #{@jogo.visitante&.nome} falhou: #{result[:error]}"
      end
      Notificacao.create!(
        user: current_user,
        tipo: :info,
        status: :unread,
        texto: texto
      )
    end

    if result[:success]
      redirect_to @jogo, notice: "Estatísticas sincronizadas com sucesso da API Zafronix!"
    else
      redirect_to @jogo, alert: "Erro ao sincronizar estatísticas: #{result[:error]}"
    end
  end




  def sync_odds
    result = Jogos::FetchOdds.sync_all
    if result[:errors].empty?
      redirect_to authenticated_root_path,
        notice: "Odds recalculadas com sucesso para #{result[:updated]} jogo(s)."
    else
      redirect_to authenticated_root_path,
        alert: "Odds calculadas para #{result[:updated]} jogo(s), mas #{result[:errors].size} erro(s) ocorreram."
    end
  rescue => e
    redirect_to authenticated_root_path, alert: "Falha ao calcular odds: #{e.message}"
  end

  def sync_all_statistics
    year = params[:year].presence || '2026'
    SyncAllStatisticsJob.perform_later(year: year, user_id: current_user.id)
    redirect_back fallback_location: authenticated_root_path, notice: "A sincronização de todas as estatísticas de jogo foi iniciada em segundo plano. Os dados de posse de bola, chutes e passes serão atualizados em breve!"
  rescue => e
    redirect_back fallback_location: authenticated_root_path, alert: "Erro ao agendar sincronização de estatísticas: #{e.message}"
  end

  def destroy
    Jogos::Destroy.new(jogo: @jogo).call

    respond_to do |format|
      format.html { redirect_to jogos_path, notice: "Jogo excluído com sucesso!.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def remove_goal
    info = @jogo.informacao_jogo
    if info && info.dados.present? && info.dados['goals'].present?
      index = params[:index].to_i
      goals = info.dados['goals'].to_a
      
      if index >= 0 && index < goals.size
        removed_goal = goals.delete_at(index)
        info.dados['goals'] = goals
        info.save!

        # Re-consolida a artilharia
        Jogos::SyncSquads.new(import_squad: false, import_goals: true).call

        redirect_to @jogo, notice: "Gol de #{removed_goal['scorer']} removido com sucesso!"
      else
        redirect_to @jogo, alert: "Gol não encontrado para remoção."
      end
    else
      redirect_to @jogo, alert: "Nenhuma informação de gol cadastrada para este jogo."
    end
  end

  def update_goal
    info = @jogo.informacao_jogo
    if info && info.dados.present? && info.dados['goals'].present?
      index = params[:index].to_i
      goals = info.dados['goals'].to_a
      
      if index >= 0 && index < goals.size
        # Atualiza os dados do gol
        goals[index]['scorer'] = params[:scorer]
        goals[index]['minute'] = params[:minute].to_i
        goals[index]['team'] = params[:team]
        goals[index]['assist'] = params[:assist].presence
        goals[index]['type'] = params[:type].presence || 'normal'
        
        info.dados['goals'] = goals
        info.save!

        # Re-consolida a artilharia
        Jogos::SyncSquads.new(import_squad: false, import_goals: true).call

        redirect_to @jogo, notice: "Gol atualizado com sucesso!"
      else
        redirect_to @jogo, alert: "Gol não encontrado para atualização."
      end
    else
      redirect_to @jogo, alert: "Nenhuma informação de gol cadastrada para este jogo."
    end
  end

  private
    def set_jogo
      @jogo = Jogo.find_by_uuid_param!(params[:id])
    end

    def load_selecoes
      @selecoes = Selecao.order(:nome)
    end

    def jogo_params
      params.require(:jogo).permit(
        :mandante_id, 
        :visitante_id, 
        :gols_mandante, 
        :gols_visitante, 
        :data, 
        :tipo, 
        :definir,
        :estadio,
        :nome_provisorio_mandante,
        :nome_provisorio_visitante,
        :status,
        :grupo_id
      )
    end
end
