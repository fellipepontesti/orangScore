class LigasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_liga, only: %i[ show edit update destroy ]

  def index
    if current_user.root?
      @ligas = Liga.all
    else 
      @ligas = Liga.joins(:liga_membros).where(liga_membros: { user_id: current_user.id })
    end
  end

  def show
    @membros_ativos = @liga.liga_membros
                          .includes(:user)
                          .where(status: :accepted)

    @membros_pendentes = @liga.liga_membros
                              .includes(:user)
                              .invited

    @membros_excluir = @liga.liga_membros
                              .includes(:user)
                              .pending_deletion

    @meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)
    @pode_convidar = @meu_vinculo&.role.in?(%w[owner admin])
  end

  def quit
    @liga = Liga.find(params[:id])

    meu_vinculo = @liga.liga_membros.find_by!(user_id: current_user.id)

    ActiveRecord::Base.transaction do

      # Se NÃO for owner → apenas sai da liga
      unless meu_vinculo.owner?
        meu_vinculo.destroy!
        redirect_to ligas_path, notice: "Você saiu da liga."
        return
      end

      # Se for owner, busca o membro mais antigo (exceto ele)
      novo_owner = @liga.liga_membros
        .where.not(id: meu_vinculo.id)
        .order(:created_at)
        .first

      # Se existir outro membro → transfere ownership
      if novo_owner
        novo_owner.update!(role: :owner)
        meu_vinculo.destroy!

        redirect_to ligas_path,
          notice: "Você saiu da liga. A liga foi transferida para: #{novo_owner.user.name}."
        return
      end

      # Se NÃO existir outro membro → remove a liga
      @liga.destroy!

      redirect_to ligas_path,
        notice: "Você saiu da liga. Como não havia outros membros, a liga foi encerrada."
    end
  end

  def remove_member
    @liga = Liga.find(params[:id])

    meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)

    unless meu_vinculo&.role.in?(%w[owner admin])
      redirect_to @liga, alert: "Você não tem permissão para remover membros."
      return
    end

    liga_membro = @liga.liga_membros.find_by(id: params[:liga_membro_id])

    if liga_membro.nil?
      redirect_to @liga, alert: "Membro não encontrado."
      return
    end

    if liga_membro.role == "owner"
      redirect_to @liga, alert: "O dono da liga não pode ser removido."
      return
    end

    # OWNER → remove direto
    if meu_vinculo.role == "owner"
      liga_membro.destroy!

      redirect_to @liga, notice: "Membro removido com sucesso."
      return
    end

    # ADMIN → solicita remoção
    if meu_vinculo.role == "admin" && liga_membro.role == "member"
      liga_membro.update!(status: :pending_deletion)

      redirect_to @liga, notice: "Solicitação de remoção enviada ao dono da liga."
      return
    end

    redirect_to @liga, alert: "Ação não permitida."
  end

  def invite_member
    @liga = Liga.find(params[:id])

    user_invited = Ligas::InviteMember.new(
      liga: @liga,
      current_user: current_user,
      email: params[:email]
    ).call

    redirect_to @liga, notice: "Convite enviado para #{user_invited.email}"
  rescue Exceptions::ServiceError => e
    redirect_to @liga, alert: e.message
  end

  def accept_invite
    liga = Ligas::AcceptInvite
              .new(params[:id], current_user.id)
              .call

    redirect_to liga_path(liga), notice: "Você entrou na liga."
  end

  def recuse_invite
    liga = Liga.find(params[:id])

    current_user.notificacoes
                .where(notificavel: liga, tipo: :convite_liga)
                .update_all(status: :read)

    redirect_to notificacoes_path, notice: "Convite recusado."
  end

  def new
    @liga = Liga.new
  end

  def edit
  end

  def create
    @liga = Liga.new(liga_params)
    @liga.owner_id = current_user.id
    @liga.membros = 1

    respond_to do |format|
      if @liga.save
        LigaMembro.create!(
          liga: @liga,
          user_id: current_user.id,
          role: :owner,
          status: :accepted
        )
        format.html { redirect_to @liga, notice: "Liga criada com sucesso!" }
        format.json { render :show, status: :created, location: @liga }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @liga.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_admin
    @liga = Liga.find(params[:id])

    meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)

    unless meu_vinculo&.role.in?(%w[owner])
      redirect_to @liga, alert: "Você não tem permissão para promover membros."
      return
    end

    liga_membro = @liga.liga_membros.find_by(id: params[:liga_membro_id])
    contexto = ""
    if liga_membro.admin? 
      liga_membro.member!
      contexto = "membro"
    else
      liga_membro.admin!
      contexto = "administrador"
    end

    redirect_to @liga, notice: "Usuário #{liga_membro.user.name} agora é #{contexto} da liga."
  end

  def update
    respond_to do |format|
      if @liga.update(liga_params)
        format.html { redirect_to @liga, notice: "Liga editada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @liga }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @liga.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ligas/1 or /ligas/1.json
  def destroy
    @liga.destroy!

    respond_to do |format|
      format.html { redirect_to ligas_path, notice: "Liga excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_liga
      @liga = Liga.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def liga_params
      params.require(:liga).permit(:owner_id, :nome)
    end
end
