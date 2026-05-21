class LigaConvitesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show accept]
  before_action :set_liga

  def show
    session[:liga_invite_token] = @liga.invite_token
    session[:referral_id] = referral_id

    return if user_signed_in?

    store_location_for(:user, request.fullpath)
    redirect_to new_user_registration_path(ref: session[:referral_id])
  end

  def accept
    unless user_signed_in?
      session[:liga_invite_token] = @liga.invite_token
      session[:referral_id] = referral_id
      store_location_for(:user, liga_convite_path(@liga.invite_token))

      redirect_to new_user_registration_path(ref: session[:referral_id])
      return
    end

    unless @liga.users.exists?(current_user.id)
      ActiveRecord::Base.transaction do
        LigaMembro.create!(
          liga: @liga,
          user: current_user,
          role: :member,
          status: :accepted
        )

        @liga.increment!(:membros)
        current_user.count_referral_for_liga!(@liga)
      end
    end

    session.delete(:liga_invite_token)
    session.delete(:referral_id)

    redirect_to @liga, notice: 'Você entrou na liga com sucesso.'
  end

  private

  def set_liga
    token = params[:token] || session[:liga_invite_token]

    @liga = Liga.find_by!(invite_token: token)
  end

  def referral_id
    params[:ref].presence || session[:referral_id].presence || @liga.owner_id
  end
end
