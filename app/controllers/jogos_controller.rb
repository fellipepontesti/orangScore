class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy ]
  before_action :load_selecoes, only: %i[new create edit update]

  def index
    @tipo_ativo = params[:tipo].presence || 'grupo'
    @grupo_ativo = @tipo_ativo == 'grupo' ? (params[:grupo].presence || 'A') : nil

    @jogos = Jogos::List.new(params: { tipo: @tipo_ativo, grupo: @grupo_ativo }).call
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
    @jogo = Jogos::Create.new(params: jogo_params).call

    respond_to do |format|
      if @jogo.persisted?
        format.html { redirect_to @jogo, notice: "Jogo criado com sucesso!." }
        format.json { render :show, status: :created, location: @jogo }
      else
        @selecoes = Selecao.order(:nome)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params).call

    respond_to do |format|
      if @jogo.errors.empty?
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

    def load_selecoes
      @selecoes = Selecao.order(:nome)
    end

    def jogo_params
      params.require(:jogo).permit(
        :mandante_id, 
        :visitante_id, 
        :gols_mandante, 
        :gols_visitante, 
        :data, 
        :tipo, 
        :definir,
        :estadio,
        :nome_provisorio_mandante,
        :nome_provisorio_visitante,
        :status
      )
    end
end
