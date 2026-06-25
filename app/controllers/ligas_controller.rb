class LigasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_liga, only: %i[ show edit update destroy quit invite_member remove_member accept_member set_admin ]
  before_action :validar_dono_da_liga!, only: %i[ edit update destroy ]
  before_action :validar_admin_da_liga!, only: %i[ accept_member invite_member remove_member ]

  def index
    @ligas = ligas_visiveis.ordenadas_por_pontos

    if params[:nome].present?
      @ligas = @ligas.where('ligas.nome ILIKE ?', "%#{params[:nome]}%")
    end

    @ligas_do_usuario = @ligas.where(owner_id: current_user.id)
    @outras_ligas = if current_user.root?
                      @ligas.where.not(owner_id: current_user.id)
                    else
                      @ligas
                        .joins(:liga_membros)
                        .where(liga_membros: { user_id: current_user.id, status: :accepted })
                        .where.not(owner_id: current_user.id)
                        .distinct
                    end
  end

  def accept_member
    liga_membro = @liga.liga_membros.find_by_uuid_param!(params[:liga_membro_id])
    liga_membro.update!(status: :accepted)
    redirect_to @liga, notice: "Membro aceito com sucesso."
  end

  def publicas
    @ligas = Liga.where(publica: true).ordenadas_por_pontos.paginate(page: params[:page], per_page: 20)
  end

  def join
    @liga = Liga.find_by_uuid_param!(params[:id])
    
    unless @liga.publica
      return redirect_to publicas_ligas_path, alert: "Esta liga não é pública."
    end
    
    if @liga.users.exists?(current_user.id)
      return redirect_to @liga, notice: "Você já participa desta liga."
    end
    
    if @liga.entrada_livre
      unless @liga.liga_membros.exists?(user_id: current_user.id, status: :accepted)
        if @liga.atingiu_limite_de_participantes?
          redirect_to publicas_ligas_path, alert: "Esta liga já atingiu o limite de participantes."
          return
        end
        LigaMembro.create!(liga: @liga, user: current_user, role: :member, status: :accepted)
        @liga.increment!(:membros)

        Notificacao.create!(
          user_id: @liga.owner_id,
          sender_id: current_user.id,
          texto: "O usuário #{current_user.name} (email: #{current_user.email}) entrou na sua liga pública #{@liga.nome}.",
          tipo: :info,
          liga_id: @liga.id,
          status: :unread,
          answered: true
        )

        redirect_to @liga, notice: "Você entrou na liga com sucesso!"
        return
      else
        redirect_to @liga, notice: "Você já participa desta liga."
        return
      end
    else
      if @liga.liga_membros.exists?(user_id: current_user.id, status: :invited)
        redirect_to publicas_ligas_path, notice: "Sua solicitação de convite já está pendente."
        return
      elsif @liga.liga_membros.exists?(user_id: current_user.id, status: :accepted)
        redirect_to @liga, notice: "Você já participa desta liga."
        return
      else
        LigaMembro.create!(liga: @liga, user: current_user, role: :member, status: :invited)

        Notificacao.create!(
          user_id: @liga.owner_id,
          sender_id: current_user.id,
          texto: "O usuário #{current_user.name} solicitou entrada na sua liga #{@liga.nome}.",
          tipo: :info,
          liga_id: @liga.id,
          status: :unread,
          answered: true
        )

        redirect_to publicas_ligas_path, notice: "Sua solicitação para entrar na liga foi enviada ao dono."
        return
      end
    end
  end

  def preview
    @liga = Liga.find_by_uuid_param!(params[:id])
    
    unless @liga.publica
      return redirect_to ligas_publicas_path, alert: "Esta liga não é pública."
    end

    points_scope = UserPoint.joins(user: :liga_membros)
                            .where(liga_membros: { liga_id: @liga.id, status: :accepted })
    palpites_scope = Palpite.joins(user: :liga_membros)
                            .where(liga_membros: { liga_id: @liga.id, status: :accepted })

    if @liga.pontuacao_zerada?
      points_scope = points_scope.where("user_points.created_at >= liga_membros.created_at")
    end

    @total_pontos = points_scope.sum(:pontos)
    @total_palpites = palpites_scope.count
  end

  def show
    # TODO: CONSIDERAR A ORDENACAO DE PONTOS DE ACORDO COM A TABELA DE PONTOS DO USUARIO
    if @liga.pontuacao_zerada?
      pontos_subquery = "COALESCE((SELECT SUM(up.pontos) FROM user_points up WHERE up.user_id = liga_membros.user_id AND up.created_at >= liga_membros.created_at), 0)"
      palpites_subquery = "COALESCE((SELECT COUNT(*) FROM palpites p WHERE p.user_id = liga_membros.user_id), 0)"
    else
      pontos_subquery = "COALESCE((SELECT SUM(up.pontos) FROM user_points up WHERE up.user_id = liga_membros.user_id), 0)"
      palpites_subquery = "COALESCE((SELECT COUNT(*) FROM palpites p WHERE p.user_id = liga_membros.user_id), 0)"
    end

    @membros_ativos = @liga.liga_membros
                          .includes(user: { user_conquistas: :conquista })
                          .where(status: :accepted)
                          .select("liga_membros.*, #{pontos_subquery} AS total_pontos_ranking, #{palpites_subquery} AS total_palpites")
                          .order('total_pontos_ranking DESC NULLS LAST, total_palpites DESC, liga_membros.created_at ASC').to_a

    @membros_pendentes = @liga.liga_membros
                              .includes(:user)
                              .invited

    @membros_excluir = @liga.liga_membros
                              .includes(:user)
                              .pending_deletion

    @meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)
    @pode_convidar = @meu_vinculo&.role.in?(%w[owner admin])
  end

  def accept_admin
    liga = Liga.find_by_uuid_param!(params[:id])
    Ligas::AcceptAdmin.new(liga: liga, current_user: current_user).call

    redirect_to liga_path(liga), notice: "Agora você é administrador da liga."
  rescue Exceptions::ServiceError => e
    redirect_to notificacoes_path, alert: e.message
  end

  def recuse_admin
    liga = Liga.find_by_uuid_param!(params[:id])
    Ligas::RecuseAdmin.new(liga: liga, current_user: current_user).call

    redirect_to notificacoes_path, notice: "Convite de administrador recusado."
  end

  def remove_member
    @meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)

    unless @meu_vinculo&.role.in?(%w[owner admin]) || current_user.root?
      return redirect_to @liga, alert: "Você não tem permissão para remover membros."
    end

    result = Ligas::RemoveMember.new(
      liga: @liga, 
      current_user: current_user, 
      liga_membro_id: params[:liga_membro_id]
    ).call

    if result[:status] == :removed
      redirect_to @liga, notice: "Membro removido com sucesso."
    else
      redirect_to @liga, notice: "Solicitação de remoção enviada ao dono da liga."
    end
  rescue Exceptions::ServiceError => e
    redirect_to @liga, alert: e.message
  end

  def quit
    Ligas::Quit.new(
      liga: @liga,
      current_user: current_user
    ).call

    redirect_to ligas_path, notice: 'Você saiu da liga com sucesso.'
  rescue StandardError => e
    redirect_to @liga, alert: e.message
  end

  def invite_member
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
    liga = Liga.find_by_uuid_param!(params[:id])

    liga = Ligas::AcceptInvite
              .new(liga.id, current_user.id)
              .call

    Notificacao.where(user_id: current_user.id, liga_id: liga.id, tipo: :invite, status: :unread).update_all(status: :read)

    redirect_to liga_path(liga), notice: "Você entrou na liga."
  end

  def recuse_invite
    liga = Liga.find_by_uuid_param!(params[:id])

    Ligas::RecuseInvite
      .new(liga.id, current_user.id)
      .call

    Notificacao.where(user_id: current_user.id, liga_id: liga.id, tipo: :invite, status: :unread).update_all(status: :read)

    redirect_to notificacoes_path, notice: "Convite recusado."
  rescue ActiveRecord::RecordNotFound
    redirect_to notificacoes_path, alert: "Convite não encontrado."
  end

  def new
    @liga = Liga.new
  end

  def edit
  end

  def create
    @liga = Ligas::Create.new(params: liga_params, current_user: current_user).call

    respond_to do |format|
      if @liga.persisted?
        format.html { redirect_to @liga, notice: "Liga criada com sucesso!" }
        format.json { render :show, status: :created, location: @liga }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @liga.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_admin
    liga_membro = Ligas::InviteAdmin.new(
      liga: @liga,
      current_user: current_user,
      liga_membro_id: params[:liga_membro_id]
    ).call

    redirect_to @liga, notice: "Convite para administrador enviado para #{liga_membro.user.name}."
  rescue Exceptions::ServiceError => e
    redirect_to @liga, alert: e.message
  end

  def validar_dono_da_liga!
    unless @liga.owner_id == current_user.id || current_user.root?
      redirect_to ligas_path, alert: "Acesso negado! Você não é o dono desta liga."
    end
  end

  def validar_admin_da_liga!
    meu_vinculo = @liga.liga_membros.find_by(user_id: current_user.id)

    return if meu_vinculo&.role.in?(%w[owner admin]) || current_user.root?

    redirect_to @liga, alert: "Você não tem permissão para gerenciar membros desta liga."
  end

  def update
    @liga = Ligas::Update.new(liga: @liga, params: liga_params).call

    respond_to do |format|
      if @liga.errors.empty?
        format.html { redirect_to @liga, notice: "Liga editada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @liga }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @liga.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    Ligas::Destroy.new(liga: @liga).call

    respond_to do |format|
      format.html { redirect_to ligas_path, notice: "Liga excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_liga
      if current_user.root?
        @liga = Liga.find_by_uuid_param!(params[:id])
      else
        @liga = Liga.joins(:liga_membros)
                    .where(uuid: params[:id])
                    .where(liga_membros: { user_id: current_user.id })
                    .where.not(liga_membros: { status: 0 })
                    .first

        if @liga.nil?
          redirect_to ligas_path, alert: "Você não tem permissão para acessar esta liga ou precisa aceitar o convite primeiro."
        end
      end
    end

    def liga_params
      params.require(:liga).permit(:owner_id, :nome, :publica, :entrada_livre, :pontuacao_zerada)
    end

    def ligas_visiveis
      return Liga.all if current_user.root?

      Liga.joins(:liga_membros)
          .where(liga_membros: { user_id: current_user.id, status: :accepted })
          .distinct
    end
end
