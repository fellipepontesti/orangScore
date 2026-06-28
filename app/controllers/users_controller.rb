class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!, except: [:pontuacao, :perfil, :edit_perfil, :update_perfil, :toggle_odds, :update_password, :ranking, :update_conquistas, :dismiss_penaltis_scoring_notice]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :change_plan]

  def index
    @usuarios = Users::List.new(params).call.paginate(page: params[:page], per_page: 10)
    @ordenacao_usuarios = Users::List::ORDER_OPTIONS
    @direcoes_ordenacao = Users::List::DIRECTION_OPTIONS
    
    @total_usuarios = User.count
    @total_premium = User.joins(:assinatura).where(assinaturas: { plano: :premium, ativa: true }).count
  end

  def pontuacao
    @user_points = current_user.user_points.includes(:jogo).order(created_at: :desc)
  end

  def ranking
    @periodo = params[:periodo].presence || 'global'
    
    if !current_user.root? && !current_user.premium?
      @periodo = 'semanal' if params[:periodo].blank?
    end

    case @periodo
    when 'diario'
      ultimo_jogo_data = Jogo.where("data < ?", Time.current.beginning_of_day).order(data: :desc).pick(:data)
      @data_ranking = ultimo_jogo_data ? ultimo_jogo_data.in_time_zone.to_date : (Time.current.in_time_zone.to_date - 1.day)
      
      start_date = @data_ranking.beginning_of_day
      end_date = @data_ranking.end_of_day
    when 'semanal'
      start_date = Time.current.beginning_of_week
      end_date = Time.current.end_of_week
    end

    if @periodo == 'global'
      if current_user.root? || current_user.premium?
        @usuarios_ranking = User
                          .joins("LEFT JOIN (SELECT user_id, SUM(pontos) as total_points FROM user_points GROUP BY user_id) points_summary ON points_summary.user_id = users.id")
                          .joins("LEFT JOIN (SELECT user_id, COUNT(id) as total_palpites FROM palpites GROUP BY user_id) palpites_summary ON palpites_summary.user_id = users.id")
                          .select("users.*, 
                                   COALESCE(points_summary.total_points, 0) as total_pontos_ranking, 
                                   COALESCE(palpites_summary.total_palpites, 0) as total_palpites")
                          .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
                          .includes(user_conquistas: :conquista)
                          .to_a
      else
        @usuarios_ranking = []
      end
    else
      points_subquery_sql = UserPoint.joins(:jogo)
                                     .where(jogos: { data: start_date..end_date })
                                     .select(:user_id, "SUM(user_points.pontos) as total_points")
                                     .group(:user_id)
                                     .to_sql

      palpites_subquery_sql = Palpite.joins(:jogo)
                                     .where(jogos: { data: start_date..end_date })
                                     .select(:user_id, "COUNT(palpites.id) as total_palpites")
                                     .group(:user_id)
                                     .to_sql

      @usuarios_ranking = User
                        .joins("LEFT JOIN (#{points_subquery_sql}) points_summary ON points_summary.user_id = users.id")
                        .joins("LEFT JOIN (#{palpites_subquery_sql}) palpites_summary ON palpites_summary.user_id = users.id")
                        .select("users.*, 
                                 COALESCE(points_summary.total_points, 0) as total_pontos_ranking, 
                                 COALESCE(palpites_summary.total_palpites, 0) as total_palpites")
                        .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
                        .includes(user_conquistas: :conquista)
                        .to_a
    end

    @current_user_ranking_index = @usuarios_ranking.index { |u| u.id == current_user.id }
    @current_user_rank = @current_user_ranking_index ? @current_user_ranking_index + 1 : nil
    @current_user_ranking_data = @usuarios_ranking[@current_user_ranking_index] if @current_user_ranking_index
  end

  def perfil
    @usuario = current_user
    @conquistas_desbloqueadas = current_user.user_conquistas.includes(:conquista).index_by(&:conquista_id)
    @todas_conquistas = Conquista.order(:id)
    @dados_grafico = Users::RankingHistoryService.new(user: current_user).call
  end

  def update_conquistas
    featured_ids = params[:featured_ids] || []
    selected_conquistas = current_user.user_conquistas.where(id: featured_ids)
    limite = current_user.premium? ? 3 : 1
    
    if selected_conquistas.count > limite
      redirect_to perfil_path, alert: "Você só pode destacar até #{limite} conquistas no seu plano."
      return
    end
    
    ActiveRecord::Base.transaction do
      current_user.user_conquistas.update_all(destacada: false)
      selected_conquistas.update_all(destacada: true)
    end
    
    redirect_to perfil_path, notice: "Conquistas em destaque atualizadas com sucesso!"
  end

  def edit_perfil
    @usuario = current_user
    @selecoes = Selecao.order(:nome)
  end

  def update_perfil
    @usuario = current_user
    atributos = perfil_params

    if atributos[:selecao_id].present? && !@usuario.selecao_editavel?
      atributos.delete(:selecao_id)
      flash.now[:alert] = "A seleção só pode ser alterada antes do primeiro jogo da Copa."
      @selecoes = Selecao.where.not(nome: "A definir").order(:nome)
      return render :edit_perfil, status: :unprocessable_entity
    end

    @usuario.update!(atributos)

    redirect_to perfil_path, notice: "Perfil atualizado com sucesso"
  rescue ActiveRecord::RecordInvalid => e
    @selecoes = Selecao.order(:nome)
    flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || e.message
    render :edit_perfil, status: :unprocessable_entity
  end

  def toggle_odds
    novo_estado = !User.first&.esconder_odds

    User.update_all(esconder_odds: novo_estado)

    status = novo_estado ? "escondidas" : "visíveis"
    flash[:notice] = "As odds foram #{status} para todos os usuários do sistema."

    redirect_back fallback_location: authenticated_root_path
  end

  def dismiss_penaltis_scoring_notice
    current_user.update_column(:penaltis_scoring_notice_seen_at, Time.current)
    redirect_back fallback_location: authenticated_root_path
  end

  def show
  end

  def edit
  end

  def update
    Users::Edit.new(@usuario.id, user_params).call

    redirect_to users_path, notice: "Usuário atualizado com sucesso"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @usuario.destroy
    redirect_to users_path, notice: "Usuário removido com sucesso"
  end

  def change_plan
    if @usuario.assinatura.update(plano: params[:plano])
      redirect_to users_path, notice: "Plano atualizado com sucesso"
    else
      redirect_to users_path, alert: "Falha ao atualizar o plano"
    end
  end

  def update_password
    @usuario = current_user
    if @usuario.update_with_password(password_params)
      bypass_sign_in(@usuario)
      redirect_to perfil_path, notice: "Senha alterada com sucesso."
    else
      redirect_to perfil_path, alert: "Erro ao alterar senha: #{@usuario.errors.full_messages.to_sentence}"
    end
  end

  private 

  def set_user
    @usuario = User.find_by_uuid_param!(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :pontos, :logo_selecao)
  end

  def perfil_params
    params.require(:user).permit(:name, :selecao_id)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def authorize_premium_or_root!
    unless current_user.root? || current_user.premium?
      redirect_to planos_path, alert: "O Ranking Global é uma funcionalidade exclusiva para assinantes Premium. Faça seu upgrade e confira sua posição!"
    end
  end
end
