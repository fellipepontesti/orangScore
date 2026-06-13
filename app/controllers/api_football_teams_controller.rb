class ApiFootballTeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!
  before_action :set_api_football_team, only: %i[update]

  def index
    @api_football_teams = ApiFootballTeam.ordenadas.includes(:selecao)
    @selecoes = Selecao.order(:nome)
    @next_pending_jogo = Jogos::FetchOdds.next_pending_game
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
    result = Jogos::FetchOdds.sync_next_pending

    if result[:skipped]
      redirect_to api_football_teams_path, notice: result[:error]
    elsif result[:success]
      jogo = result[:jogo]
      redirect_to api_football_teams_path, notice: "Odds calculadas localmente com sucesso para #{jogo.mandante&.nome} x #{jogo.visitante&.nome}."
    else
      redirect_to api_football_teams_path, alert: "Falha ao calcular odds: #{result[:error]}"
    end
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
