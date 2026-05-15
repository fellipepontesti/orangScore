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
    # Ranking Global para todos
    todos_usuarios = User.all.sort_by { |u| -(u.total_pontos || 0) }
    @ranking_global = todos_usuarios.first(5)
    @user_global_rank = todos_usuarios.index(current_user) + 1
  end
end
