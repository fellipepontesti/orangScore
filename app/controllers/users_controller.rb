class UsersController < ApplicationController
  def index
    @usuarios = Users::List.new(params).call
  end

  def show
  end

  def edit
    usuario = Users::Edit.new(params[:id], user_params).call

    redirect_to usuarios_path, notice: "Usuário atualizado com sucesso"
  rescue ActiveRecord::RecordInvalid => e
    @usuario = User.find(params[:id])
    flash.now[:alert] = e.message
    render :edit, status: :unprocessable_entity
  end

  private 

  def user_params
    params.require(:user).permit(:name, :email, :pontos, :logo_selecao)
  end
end
