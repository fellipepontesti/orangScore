class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index 
    @ligas_ativas = current_user.liga_membros.where(status: :accepted).count
    @jogos_hoje = Jogo.where(data: Date.today.beginning_of_day..Date.today.end_of_day).count
    @proximos_jogos = Jogo.where("data >= ?", Time.current).order(data: :asc).limit(5)
    
    @liga_principal = current_user.ligas_participadas.first
    if @liga_principal
      @ranking_liga = @liga_principal.liga_membros
                                     .includes(:user)
                                     .where(status: :accepted)
                                     .sort_by { |lm| -(lm.user.total_pontos || 0) }
                                     .first(5)
    end

    # Ranking Global para todos
    # Ranking Global com as regras oficiais (Pontos > Palpites > Antiguidade)
    todos_usuarios = User
                      .joins("LEFT JOIN user_points ON user_points.user_id = users.id")
                      .joins("LEFT JOIN palpites ON palpites.user_id = users.id")
                      .group("users.id")
                      .select("users.*, 
                               COALESCE(SUM(user_points.pontos), 0) as total_pontos_ranking, 
                               COUNT(DISTINCT palpites.id) as total_palpites")
                      .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC").to_a

    @ranking_global = todos_usuarios.first(5)
    @user_global_rank = todos_usuarios.index(current_user) ? todos_usuarios.index(current_user) + 1 : "-"
  end
end
