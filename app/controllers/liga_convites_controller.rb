class LigaConvitesController < ApplicationController
  before_action :set_liga

  def show
    session[:liga_invite_token] = @liga.invite_token

    return if user_signed_in?

    store_location_for(:user, request.fullpath)
    redirect_to new_user_registration_path
  end

  def accept
    unless user_signed_in?
      session[:liga_invite_token] = @liga.invite_token
      store_location_for(:user, liga_convite_path(@liga.invite_token))

      redirect_to new_user_registration_path
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