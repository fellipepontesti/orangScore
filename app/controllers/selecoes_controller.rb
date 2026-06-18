class SelecoesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!, except: %i[index show]
  before_action :load_grupos, only: %i[new create edit update]
  before_action :logos_disponiveis, only: %i[new create edit update]
  before_action :set_selecao, only: %i[ show edit update destroy ]

  def index
    @selecoes = Selecoes::List.new(params).call
  end

  def show
  end

  def new
    @selecao = Selecao.new
  end

  def edit
    @selecao = Selecao.find_by_uuid_param!(params[:id])
  end

  def create
    @selecao = Selecoes::Create.new(params: selecao_params).call

    if @selecao.errors[:base].include?("Grupo cheio!")
      flash.now[:alert] = "Grupo cheio!"
      render :new, status: :unprocessable_entity
      return
    end

    respond_to do |format|
      if @selecao.persisted?
        format.html { redirect_to @selecao, notice: "Seleção criada com sucesso!" }
        format.json { render :show, status: :created, location: @selecao }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @selecao = Selecoes::Update.new(selecao: @selecao, params: selecao_params).call

    respond_to do |format|
      if @selecao.errors.empty?
        format.html { redirect_to @selecao, notice: "Seleção editada com sucesso!", status: :see_other }
        format.json { render :show, status: :ok, location: @selecao }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    Selecoes::Destroy.new(selecao: @selecao).call

    respond_to do |format|
      format.html { redirect_to selecoes_path, notice: "Seleção excluída com sucesso!", status: :see_other }
      format.json { head :no_content }
    end
  end



  def sync_squads
    year = params[:year].presence || '2026'

    if params[:sync_all] == 'true'
      SyncSquadsJob.perform_later(year: year)
      redirect_back fallback_location: authenticated_root_path, notice: "A sincronização de todas as seleções foi iniciada em segundo plano. Os elencos estarão atualizados em breve!"
      return
    end

    selecao = Selecao.find_by(id: params[:selecao_id])
    api_name = params[:api_name].to_s.strip

    unless selecao
      redirect_back fallback_location: authenticated_root_path, alert: "Seleção não encontrada no sistema."
      return
    end

    if api_name.blank?
      redirect_back fallback_location: authenticated_root_path, alert: "Nome da seleção para busca na API não informado."
      return
    end

    SyncSquadsJob.perform_later(selecao_id: selecao.id, api_name: api_name, year: year)

    redirect_to selecao_path(selecao), notice: "A sincronização do elenco de \"#{selecao.nome}\" foi iniciada em segundo plano. A escalação estará atualizada em instantes!"
  rescue => e
    redirect_back fallback_location: authenticated_root_path, alert: "Erro ao agendar sincronização: #{e.message}"
  end

  def sync_squads_only
    year = params[:year].presence || '2026'
    SyncSquadsOnlyJob.perform_later(year: year)
    redirect_back fallback_location: authenticated_root_path, notice: "A sincronização de todos os elencos foi iniciada em segundo plano. Os elencos estarão atualizados em breve!"
  rescue => e
    redirect_back fallback_location: authenticated_root_path, alert: "Erro ao agendar sincronização: #{e.message}"
  end

  def sync_players_data
    year = params[:year].presence || '2026'
    SyncPlayersDataJob.perform_later(year: year)
    redirect_back fallback_location: authenticated_root_path, notice: "A sincronização de gols e assistências dos jogadores foi iniciada em segundo plano. Os dados estarão atualizados em breve!"
  rescue => e
    redirect_back fallback_location: authenticated_root_path, alert: "Erro ao agendar sincronização: #{e.message}"
  end

  private
    def set_selecao
      @selecao = Selecao.find_by_uuid_param!(params[:id])
    end

    def selecao_params
      params.require(:selecao).permit(:nome, :pontos, :jogos, :vitorias, :derrotas, :empates, :logo, :grupo_id)
    end

    def logos_disponiveis
      @logos = Dir.entries(Rails.root.join('app/assets/images/selecoes'))
        .select { |f| f.ends_with?('.png') }
        .sort_by { |f| f.downcase }
    end

    def load_grupos
      @grupos = Grupo.order(:nome)
    end
end
