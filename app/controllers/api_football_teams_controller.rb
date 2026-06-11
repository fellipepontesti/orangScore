class ApiFootballTeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!
  before_action :set_api_football_team, only: %i[update]

  def index
    @api_football_teams = ApiFootballTeam.ordenadas.includes(:selecao)
    @selecoes = Selecao.order(:nome)
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
    redirect_to api_football_teams_path, notice: "Sincronização concluída. Registros criados: #{@report[:created].size}, atualizados: #{@report[:updated].size}, erros: #{@report[:errors].size}."
  rescue => e
    redirect_to api_football_teams_path, alert: "Falha na sincronização: #{e.message}"
  end

  private

  def set_api_football_team
    @api_football_team = ApiFootballTeam.find(params[:id])
  end

  def api_football_team_params
    params.require(:api_football_team).permit(:selecao_id)
  end
end
