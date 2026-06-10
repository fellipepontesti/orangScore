class PalpitesController < ApplicationController
  before_action :set_palpite, only: %i[ show edit update destroy ]

  # GET /palpites or /palpites.json
  def index
    @palpites = Palpite.all
  end

  # GET /palpites/1 or /palpites/1.json
  def show
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

  # DELETE /palpites/1 or /palpites/1.json
  def destroy
    @palpite.destroy!

    respond_to do |format|
      format.html { redirect_to palpites_path, notice: "Palpite was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_palpite
      @palpite = current_user.palpites.find_by_uuid_param!(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def palpite_params
      params.require(:palpite).permit(:jogo_id, :gols_casa, :gols_fora)
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
