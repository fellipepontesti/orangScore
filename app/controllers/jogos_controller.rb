class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy start finalize finish ]
  before_action :load_selecoes, only: %i[new create edit update finalize]
  before_action :authorize_root_or_semi_root!, only: %i[start update finish]
  before_action :authorize_root!, except: %i[index show start update finish]

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
      redirect_to @jogo, notice: "Jogo finalizado com sucesso! Pontuações calculadas."
    else
      render :finalize, status: :unprocessable_entity
    end
  end

  def sync
    @sync_report = Jogos::SyncFromFootballApi.new.call
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

  def destroy
    Jogos::Destroy.new(jogo: @jogo).call

    respond_to do |format|
      format.html { redirect_to jogos_path, notice: "Jogo excluído com sucesso!.", status: :see_other }
      format.json { head :no_content }
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
