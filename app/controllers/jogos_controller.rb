class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy ]

  def index
    @jogos = Jogo.all.order(:data)

    @mata_mata = {
      "Oitavas de final" => 8,
      "Quartas de final" => 4,
      "Semifinal" => 2,
      "Final" => 1
    }
  end

  def show
  end

  def new
    @jogo = Jogo.new
    @selecoes = Selecao.order(:nome)
  end

  def edit
    @selecoes = Selecao.order(:nome)
  end

  def create
    @jogo = Jogo.new(jogo_params)

    respond_to do |format|
      if @jogo.save
        format.html { redirect_to @jogo, notice: "Jogo criado com sucesso!." }
        format.json { render :show, status: :created, location: @jogo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @selecoes = Selecao.order(:nome)

    respond_to do |format|
      if @jogo.update(jogo_params)
        format.html { redirect_to @jogo, notice: "Jogo atualizado com sucesso!.", status: :see_other }
        format.json { render :show, status: :ok, location: @jogo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @jogo.destroy!

    respond_to do |format|
      format.html { redirect_to jogos_path, notice: "Jogo excluído com sucesso!.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_jogo
      @jogo = Jogo.find(params[:id])
    end

    def jogo_params
      params.require(:jogo).permit(:mandante_id, :visitante_id, :gols_mandante, :gols_visitante, :data)
    end
end
