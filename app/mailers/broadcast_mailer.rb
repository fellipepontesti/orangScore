class BroadcastMailer < ApplicationMailer
  def broadcast_email
    @user_email = params[:user_email]
    @user_name = params[:user_name]
    @assunto = params[:assunto]
    @mensagem = params[:mensagem]
    @sender_email = params[:sender_email]
    @sender_name = params[:sender_name]

    mail(
      to: @user_email,
      subject: @assunto,
      reply_to: @sender_email
    )
  end
end
