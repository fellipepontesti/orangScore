class DashboardController < ApplicationController
  include JogosHelper

  before_action :authenticate_user!
  before_action :authorize_root!, only: [:convites_pendentes, :aceitar_convite, :negar_convite, :new_user, :create_user, :artilharia]

  def index 
    if current_user.semi_root?
      @jogos_em_andamento = Jogo.em_andamento.order(data: :asc)
      @jogos_de_hoje = Jogo.programado
                            .where(definir: false)
                            .where(data: Time.current.beginning_of_day..Time.current.end_of_day)
                            .order(data: :asc)
      return render :semi_root_index
    end

    if current_user.root?
      @total_usuarios = User.count
      @total_online = User.where('last_seen_at > ?', 5.minutes.ago).count
      @total_palpites = Palpite.count
      @total_premium = User.joins(:assinatura).where(assinaturas: { plano: :premium, ativa: true }).count
      @total_jogos = Jogo.count
      @total_ligas = Liga.count
      @ultimos_usuarios = User.includes(:palpites).order(created_at: :desc).limit(5)
      @jogos_em_andamento = Jogo.em_andamento.order(data: :asc).limit(10)
      @jogos_programados = Jogo.programado
                                .where(definir: false)
                                .where(data: Time.current.beginning_of_day..Time.current.end_of_day)
                                .order(data: :asc)
      @next_jogo_rapido = next_jogo_rapido(current_user)
      @jogos_pendentes = jogos_pendentes_count(current_user)
      return render :root_index
    end
    @next_jogo_rapido = next_jogo_rapido(current_user)
    @jogos_pendentes = jogos_pendentes_count(current_user)
    @ligas_ativas = current_user.liga_membros.where(status: :accepted).count
    hoje = Time.zone.today
    periodo_hoje = hoje.beginning_of_day..hoje.end_of_day
    @jogos_de_hoje = Jogo
      .includes(:mandante, :visitante, :palpites)
      .where(status: :em_andamento)
      .or(
        Jogo.includes(:mandante, :visitante, :palpites)
            .where(status: :programado, definir: false, data: periodo_hoje)
      )
      .order(Arel.sql("CASE jogos.status WHEN #{Jogo.statuses[:em_andamento]} THEN 0 ELSE 1 END"), :data)
    @palpites_por_jogo_id = current_user.palpites.where(jogo_id: @jogos_de_hoje.map(&:id)).index_by(&:jogo_id)
    @proximos_jogos = Jogo.where("data >= ?", Time.current).order(data: :asc).limit(5)
    
    @liga_principal = current_user.ligas_participadas.first
    if @liga_principal
      @ranking_liga = @liga_principal.liga_membros
                                     .includes(:user)
                                     .where(status: :accepted)
                                     .sort_by { |lm| -(lm.user.total_pontos || 0) }
                                     .first(5)
    end

    @ligas_publicas = Liga.where(publica: true).order(membros: :desc).limit(5)

    # Ranking Global para todos
    # Ranking Global com as regras oficiais (Pontos > Palpites > Antiguidade)
    todos_usuarios = User
                      .select("users.*,
                               COALESCE((SELECT SUM(up.pontos) FROM user_points up WHERE up.user_id = users.id), 0) AS total_pontos_ranking,
                               COALESCE((SELECT COUNT(*) FROM palpites p WHERE p.user_id = users.id), 0) AS total_palpites")
                      .order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
                      .to_a

    @ranking_global = todos_usuarios.first(5)
    @user_global_rank = todos_usuarios.index(current_user) ? todos_usuarios.index(current_user) + 1 : "-"
  end

  def convites_pendentes
    @convites = LigaMembro.invited.includes(:user, liga: :owner).order(created_at: :desc)
  end

  def aceitar_convite
    liga_membro = LigaMembro.find_by_uuid_param!(params[:liga_membro_id])
    
    ActiveRecord::Base.transaction do
      liga_membro.update!(status: :accepted)
      liga_membro.liga.increment!(:membros)
      liga_membro.user.count_referral_for_liga!(liga_membro.liga)
    end

    redirect_to dashboard_convites_pendentes_path, notice: "Solicitação do usuário #{liga_membro.user.name} para entrar na liga '#{liga_membro.liga.nome}' aceita com sucesso!"
  end

  def negar_convite
    liga_membro = LigaMembro.find_by_uuid_param!(params[:liga_membro_id])
    user_name = liga_membro.user.name
    liga_nome = liga_membro.liga.nome
    liga_membro.destroy!

    redirect_to dashboard_convites_pendentes_path, notice: "Solicitação do usuário #{user_name} para entrar na liga '#{liga_nome}' rejeitada com sucesso."
  end

  def new_user
    @usuario = User.new(tipo: :root)
  end

  def create_user
    @usuario = User.new(user_create_params)
    
    temp_password = SecureRandom.alphanumeric(12) + "aA1!"
    @usuario.password = temp_password
    @usuario.password_confirmation = temp_password
    @usuario.selecao_id = Selecao.find_by(nome: 'A definir')&.id || Selecao.first&.id
    @usuario.tipo = :semi_root
    @usuario.terms_of_service = '1'
    @usuario.esconder_odds = false

    @usuario.skip_confirmation!

    if @usuario.save
      redirect_to authenticated_root_path, notice: "Usuário Operador (Semi-Root) criado com sucesso! E-mail: #{@usuario.email} | Senha temporária: #{temp_password}"
    else
      flash.now[:alert] = "Erro ao criar usuário: #{@usuario.errors.full_messages.to_sentence}"
      render :new_user, status: :unprocessable_entity
    end
  end

  def artilharia
    @artilheiros = Jogador.includes(:selecao)
                          .where("gols > 0")
                          .order(gols: :desc, nome: :asc)
  end

  private

  def user_create_params
    params.require(:user).permit(:name, :email)
  end
end
