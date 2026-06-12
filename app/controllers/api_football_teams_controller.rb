class ApiFootballTeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!
  before_action :set_api_football_team, only: %i[update]

  def index
    @api_football_teams = ApiFootballTeam.ordenadas.includes(:selecao)
    @selecoes = Selecao.order(:nome)
    @next_pending_selecao = ApiFootballTeams::Sync.new.next_pending_selection
  end

  def update
    if @api_football_team.update(api_football_team_params)
      redirect_to api_football_teams_path, notice: "Associação atualizada com sucesso."
    else
      flash.now[:alert] = "Não foi possível atualizar a associação."
      @api_football_teams = ApiFootballTeam.ordenadas.includes(:selecao)
      @selecoes = Selecao.order(:nome)
      render :index, status: :unprocessable_entity
    end
  end

  def sync
    @report = ApiFootballTeams::Sync.new.call
    skipped_count = @report[:skipped] ? @report[:skipped].size : 0
    processed = (@report[:created] + @report[:updated]).first

    if processed
      redirect_to api_football_teams_path, notice: "Sincronização de 1 seleção concluída: #{processed.selecao&.nome || processed.name} (API ID: #{processed.api_id})."
    elsif @report[:errors].any?
      error = @report[:errors].first
      redirect_to api_football_teams_path, alert: "Falha ao sincronizar #{error[:name]}: #{error[:error]}"
    else
      redirect_to api_football_teams_path, notice: "Nenhuma seleção pendente para sincronizar. Ignorados: #{skipped_count}."
    end
  rescue => e
    redirect_to api_football_teams_path, alert: "Falha na sincronização: #{e.message}"
  end

  def sync_brazil
    result = ApiFootballTeams::Sync.new.sync_next_pending_team
    if result[:success]
      status_label = result[:new_record] ? "criada" : "atualizada"
      redirect_to api_football_teams_path, notice: "Teste da próxima seleção concluído: #{result[:selecao].nome}. Associação #{status_label} (API ID: #{result[:api_team].api_id})."
    elsif result[:skipped]
      redirect_to api_football_teams_path, notice: result[:reason]
    else
      selection_name = result[:selecao]&.nome || "próxima seleção"
      redirect_to api_football_teams_path, alert: "Falha no teste de #{selection_name}: #{result[:error]}"
    end
  rescue => e
    redirect_to api_football_teams_path, alert: "Erro ao testar próxima seleção: #{e.message}"
  end

  private

  def set_api_football_team
    @api_football_team = ApiFootballTeam.find(params[:id])
  end

  def api_football_team_params
    params.require(:api_football_team).permit(:selecao_id)
  end
end
