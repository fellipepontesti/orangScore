class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy start finalize finish ]
  before_action :load_selecoes, only: %i[new create edit update finalize]
  before_action :authorize_root!, except: %i[index show]

  def index
    @tipo_ativo = params[:tipo].presence || 'grupo'
    @grupos = Grupo.order(:nome)

    @grupo_ativo = if params[:grupo].present?
      params[:grupo]
    else
      @grupos.first&.id
    end
    
    @status_filtro = params[:status]
    @data_inicio = params[:start_date]
    @data_fim = params[:end_date]

    @jogos = Jogos::List.new(params: {
      tipo: @tipo_ativo,
      grupo: @grupo_ativo,
      status: @status_filtro,
      start_date: @data_inicio,
      end_date: @data_fim
    }).call
  end

  def show
  end

  def new
    @jogo = Jogo.new
    @selecoes = Selecao.order(:nome)
    @grupos = Grupo.order(:nome)
  end

  def edit
    @jogo = Jogo.find(params[:id])
    @selecoes = Selecao.order(:nome)
    @grupos = Grupo.order(:nome)
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

  def start
    Jogos::Start.new(jogo: @jogo).call
    redirect_to @jogo, notice: "Jogo iniciado com sucesso! Notificações enviadas."
  rescue => e
    redirect_to @jogo, alert: e.message
  end

  def finalize
  end

  def finish
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params.merge(status: 'finalizado')).call

    if @jogo.errors.empty?
      redirect_to @jogo, notice: "Jogo finalizado com sucesso! Pontuações calculadas."
    else
      render :finalize, status: :unprocessable_entity
    end
  end

  def destroy
    Jogos::Destroy.new(jogo: @jogo).call

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
        :status,
        :grupo_id
      )
    end
end
