class NotificacoesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!, only: %i[ new create edit update destroy ]
  before_action :set_notificacao, only: %i[ show edit update destroy ]

  def index
    @notificacoes = Notificacao.where(user_id: current_user.id)
  end

  def show
    @notificacao.read!
  end

  def new
    @notificacao = Notificacao.new(tipo: :system, status: :unread)
  end

  def edit
  end

  def create
    @notificacao = Notificacao.new(notificacao_params.merge(
      user: current_user,
      sender: current_user,
      tipo: :system,
      status: :unread
    ))

    respond_to do |format|
      if @notificacao.valid?
        created_count = Notificacoes::Broadcast.new(
          texto: @notificacao.texto,
          sender: current_user
        ).call

        format.html { redirect_to notificacoes_path, notice: "#{created_count} notificações enviadas com sucesso." }
        format.json { render json: { created_count: created_count }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @notificacao.update(notificacao_params)
        format.html { redirect_to @notificacao, notice: "Notificacao was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @notificacao }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @notificacao.destroy!

    respond_to do |format|
      format.html { redirect_to notificacoes_path, notice: "Notificacao was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def accept_admin_invite
    notificacao = current_user.notificacoes.find(params[:id])

    unless notificacao.admin_invite? && notificacao.unread?
      redirect_to notificacoes_path, alert: 'Convite inválido.'
      return
    end

    liga_membro = notificacao.liga.liga_membros.find_by(user_id: current_user.id)

    unless liga_membro
      redirect_to notificacoes_path, alert: 'Vínculo com a liga não encontrado.'
      return
    end

    liga_membro.admin!
    notificacao.read!

    redirect_to notificacao.liga, notice: 'Você agora é administrador da liga.'
  end

  def reject_admin_invite
    notificacao = current_user.notificacoes.find(params[:id])

    unless notificacao.admin_invite? && notificacao.unread?
      redirect_to notificacoes_path, alert: 'Convite inválido.'
      return
    end

    notificacao.read!

    redirect_to notificacoes_path, notice: 'Convite recusado.'
  end

  private
    def set_notificacao
      @notificacao = if current_user.root?
        Notificacao.find(params[:id])
      else
        current_user.notificacoes.find(params[:id])
      end
    end

    def notificacao_params
      params.require(:notificacao).permit(:texto)
    end
end
