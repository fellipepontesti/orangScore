class PalpitesController < ApplicationController
  before_action :set_palpite, only: %i[ show edit update ]

  # GET /palpites or /palpites.json
  def index
    @order_options = {
      "recentes" => "Mais recentes",
      "antigos" => "Mais antigos",
      "pontuacao" => "Maior pontuação"
    }
    @points_options = {
      "" => "Todas as pontuações",
      "sem_pontos" => "Sem pontuação",
      "10" => "10 pontos - Placar Exato",
      "7" => "7 pontos - Vencedor/Empate + Gols de um time",
      "5" => "5 pontos - Apenas Vencedor/Empate",
      "2" => "2 pontos - Participação"
    }
    @usuarios_filter = User.order(:name) if current_user.root?

    @palpites = filtered_palpites.to_a
    @points_by_palpite_id = points_by_palpite_id(@palpites)
  end

  # GET /palpites/1 or /palpites/1.json
  def show
    @pontos = UserPoint.where(user_id: @palpite.user_id, jogo_id: @palpite.jogo_id)
                       .where.not(motivo: "Campeão do Torneio")
                       .first&.pontos
  end

  # GET /palpites/new
  def new
    @jogo = Jogo.find_by_uuid_param!(params[:jogo_id])
    @palpite = current_user.palpites.build
    @palpite.jogo = @jogo
  end

  # GET /palpites/1/edit
  def edit
    @jogo = @palpite.jogo
  end

  def create
    @jogo = Jogo.find_by(uuid: palpite_params[:jogo_id])
    @palpite = current_user.palpites.build(palpite_params.except(:jogo_id))

    unless @jogo
      redirect_to jogos_path, alert: "Jogo não informado."
      return
    end

    if @jogo.finalizado? || @jogo.em_andamento?
      redirect_to jogos_path, alert: "Não é possível palpitar em jogos em andamento ou finalizados."
      return
    end

    @palpite.jogo = @jogo

    respond_to do |format|
      if @palpite.save
        format.html { handle_quick_mode_redirect("Palpite criado com sucesso!") }
        format.json { render :show, status: :created, location: @palpite }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @palpite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /palpites/1 or /palpites/1.json
  def update
    @jogo = @palpite.jogo

    if @jogo.finalizado? || @jogo.em_andamento?
      redirect_to jogos_path, alert: "Não é possível editar palpites de jogos em andamento ou finalizados."
      return
    end

    respond_to do |format|
      if @palpite.update(palpite_params.except(:jogo_id))
        format.html { handle_quick_mode_redirect("Palpite atualizado com sucesso!") }
        format.json { render :show, status: :ok, location: @palpite }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @palpite.errors, status: :unprocessable_entity }
      end
    end
  end



  private
    # Use callbacks to share common setup or constraints between actions.
    def set_palpite
      @palpite = if current_user.root?
        Palpite.find_by_uuid_param!(params[:id])
      else
        current_user.palpites.find_by_uuid_param!(params[:id])
      end
    end

    # Only allow a list of trusted parameters through.
    def palpite_params
      params.require(:palpite).permit(:jogo_id, :gols_casa, :gols_fora)
    end

    def filtered_palpites
      scope = current_user.root? ? Palpite.all : current_user.palpites
      scope = scope.joins(:jogo)

      scope = scope.joins(<<~SQL.squish)
        LEFT JOIN user_points ON user_points.jogo_id = palpites.jogo_id 
                             AND user_points.user_id = palpites.user_id 
                             AND user_points.motivo != 'Campeão do Torneio'
      SQL

      if current_user.root? && params[:user_id].present?
        scope = scope.where(user_id: params[:user_id])
      end

      if params[:status].present? && Jogo.statuses.key?(params[:status])
        scope = scope.where(jogos: { status: params[:status] })
      end

      if params[:pontos].present?
        if params[:pontos] == "sem_pontos"
          scope = scope.where(user_points: { pontos: nil })
        else
          scope = scope.where(user_points: { pontos: params[:pontos].to_i })
        end
      end

      scope = scope.includes(:user, jogo: [:mandante, :visitante])
      order_palpites(scope)
    end

    def order_palpites(scope)
      case params[:order]
      when "recentes"
        scope.order("jogos.data DESC, palpites.created_at DESC")
      when "antigos"
        scope.order("jogos.data ASC, palpites.created_at ASC")
      when "pontuacao"
        scope.order(Arel.sql("COALESCE(user_points.pontos, 0) DESC, jogos.data ASC"))
      else
        # 1. Jogos em andamento são prioridade máxima
        # 2. Próximos jogos/Programados vêm em segundo (Peso 2)
        # 3. Jogos já finalizados ou outros vão para o fim (Peso 3)
        
        status_priority = <<~SQL.squish
          CASE 
            WHEN jogos.status = #{Jogo.statuses[:em_andamento]} THEN 1
            WHEN jogos.status = #{Jogo.statuses[:programado]} THEN 2
            ELSE 3
          END ASC
        SQL

        scope.order(Arel.sql(status_priority)).order("jogos.data ASC, palpites.created_at DESC")
      end
    end

    def points_by_palpite_id(palpites)
      ids = palpites.map(&:id)
      return {} if ids.empty?

      UserPoint
        .joins("INNER JOIN palpites ON palpites.jogo_id = user_points.jogo_id AND palpites.user_id = user_points.user_id")
        .where(palpites: { id: ids })
        .where.not(user_points: { motivo: "Campeão do Torneio" })
        .pluck("palpites.id", "user_points.pontos")
        .to_h
    end

    def handle_quick_mode_redirect(success_message)
      if params[:quick_mode] == 'true' || params[:quick_mode].present?
        next_jogo = Jogo.where(status: :programado, definir: false)
                        .where.not(id: current_user.palpites.select(:jogo_id))
                        .order(:data)
                        .first

        if next_jogo
          redirect_to new_palpite_path(jogo_id: next_jogo.uuid, quick_mode: true), notice: "#{success_message} Próximo jogo..."
        else
          redirect_to jogos_path, notice: "Parabéns! Você palpitou em todos os jogos disponíveis no momento."
        end
      else
        redirect_to jogos_path(tipo: @jogo.tipo, grupo: @jogo.grupo&.uuid), notice: success_message
      end
    end
end
