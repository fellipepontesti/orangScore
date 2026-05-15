class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!, except: [:pontuacao]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @usuarios = Users::List.new(params).call
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

  private 

  def set_user
    @usuario = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :pontos, :logo_selecao)
  end
end
