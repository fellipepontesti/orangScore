class EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!

  def new
  end

  def create
    assunto = params[:assunto].to_s.strip
    mensagem = params[:mensagem].to_s.strip

    if assunto.blank? || mensagem.blank?
      flash.now[:alert] = "O assunto e a mensagem são obrigatórios."
      render :new, status: :unprocessable_entity
      return
    end

    sent_count = Emails::Broadcast.new(
      assunto: assunto,
      mensagem: mensagem,
      sender: current_user
    ).call

    redirect_to new_email_path, notice: "#{sent_count} e-mails foram enfileirados para envio com sucesso!"
  rescue ArgumentError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
end
