class LigaInviteMailer < ApplicationMailer
  def invite_member
    @user = params[:user]
    @liga = params[:liga]
    @invited_by = params[:invited_by]

    mail(
      to: @user.email,
      subject: "Você recebeu um convite para participar da liga #{@liga.nome}"
    )
  end
end