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
    @jogo = Jogo.find(params[:jogo_id])
    @palpite = current_user.palpites.build
    @palpite.jogo = @jogo
  end

  # GET /palpites/1/edit
  def edit
    @jogo = @palpite.jogo
  end

  def create
    @palpite = current_user.palpites.build(palpite_params)
    @jogo = Jogo.find_by(id: palpite_params[:jogo_id])

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
        format.html { redirect_to jogos_path(tipo: @jogo.tipo), notice: "Palpite criado com sucesso!." }
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
      if @palpite.update(palpite_params)
        format.html { redirect_to jogos_path(tipo: @jogo.tipo), notice: "Palpite atualizado com sucesso!." }
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
      @palpite = current_user.palpites.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def palpite_params
      params.require(:palpite).permit(:jogo_id, :gols_casa, :gols_fora)
    end
end
