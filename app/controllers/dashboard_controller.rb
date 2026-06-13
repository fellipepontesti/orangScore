class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index 
    if current_user.root?
      @total_usuarios = User.count
      @total_palpites = Palpite.count
      @total_plus = User.joins(:assinatura).where(assinaturas: { plano: :plus, ativa: true }).count
      @total_premium = User.joins(:assinatura).where(assinaturas: { plano: :premium, ativa: true }).count
      @total_jogos = Jogo.count
      @total_ligas = Liga.count
      @ultimos_usuarios = User.order(created_at: :desc).limit(5)
      @jogos_em_andamento = Jogo.em_andamento.order(data: :asc).limit(10)
      @jogos_programados = Jogo.programado
                                .where(definir: false)
                                .where(data: Time.current.beginning_of_day..Time.current.end_of_day)
                                .order(data: :asc)
      return render :root_index
    end
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
end
