class LigaConvitesController < ApplicationController
  before_action :set_liga

  def show
    session[:liga_invite_token] = @liga.invite_token

    return if user_signed_in?

    redirect_to new_user_session_path
  end

  def accept
    unless user_signed_in?
      session[:liga_invite_token] = @liga.invite_token

      redirect_to new_user_session_path
      return
    end

    unless @liga.users.exists?(current_user.id)
      LigaMembro.create!(
        liga: @liga,
        user: current_user,
        role: :member,
        status: :accepted
      )

      @liga.increment!(:membros)
    end

    session.delete(:liga_invite_token)

    redirect_to @liga, notice: 'Você entrou na liga com sucesso.'
  end

  private

  def set_liga
    token = params[:token] || session[:liga_invite_token]

    @liga = Liga.find_by!(invite_token: token)
  end
end