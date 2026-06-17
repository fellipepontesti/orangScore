class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!, except: [:pontuacao, :perfil, :edit_perfil, :update_perfil, :toggle_odds, :update_password]
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
    # Ranking Global com as regras oficiais (Pontos > Palpites > Antiguidade)
    @usuarios_ranking = User
                      .joins("LEFT JOIN user_points ON user_points.user_id = users.id")
                      .joins("LEFT JOIN palpites ON palpites.user_id = users.id")
                      .group("users.id")
                      .select("users.*, 
                               COALESCE(SUM(user_points.pontos), 0) as total_pontos_ranking, 
                               COUNT(DISTINCT palpites.id) as total_palpites")
                      .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
                      .paginate(page: params[:page], per_page: 50)
  end

  def perfil
    @usuario = current_user
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
end
