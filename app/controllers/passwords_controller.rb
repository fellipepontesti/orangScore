class PasswordsController < ApplicationController
  def new
  end

  def request_recovery
    PasswordRecovery::RequestNewPassword.new(params[:email]).call

    redirect_to new_user_session_path,
      notice: 'Se o e-mail existir, você receberá instruções para redefinir a senha'
  end

  def edit
    @user = User.find_by(password_recovery_token: params[:token])

    unless @user
      redirect_to new_password_path, alert: 'Token inválido ou expirado'
    end
  end

  def update
    @user = User.find_by(password_recovery_token: params[:token])

    unless @user
      redirect_to new_password_path, alert: 'Token inválido ou expirado'
      return
    end

    if @user.update(password_params)
      @user.update(password_recovery_token: nil)

      redirect_to new_user_session_path,
        notice: 'Senha redefinida com sucesso'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
