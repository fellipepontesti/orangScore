class SelecoesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_grupos, only: %i[new create edit update]
  before_action :logos_disponiveis, only: %i[new create edit update]
  before_action :set_selecao, only: %i[ show edit update destroy ]

  def index
    @selecoes = Selecoes::List.new(params).call
  end

  def show
  end

  def new
    @selecao = Selecao.new
  end

  def edit
    @selecao = Selecao.find(params[:id])
  end

  def create
    @selecao = Selecoes::Create.new(params: selecao_params).call

    if @selecao.errors[:base].include?("Grupo cheio!")
      flash.now[:alert] = "Grupo cheio!"
      render :new, status: :unprocessable_entity
      return
    end

    respond_to do |format|
      if @selecao.persisted?
        format.html { redirect_to @selecao, notice: "Seleção criada com sucesso!" }
        format.json { render :show, status: :created, location: @selecao }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @selecao = Selecoes::Update.new(selecao: @selecao, params: selecao_params).call

    respond_to do |format|
      if @selecao.errors.empty?
        format.html { redirect_to @selecao, notice: "Seleção editada com sucesso!", status: :see_other }
        format.json { render :show, status: :ok, location: @selecao }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    Selecoes::Destroy.new(selecao: @selecao).call

    respond_to do |format|
      format.html { redirect_to selecoes_path, notice: "Seleção excluída com sucesso!", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_selecao
      @selecao = Selecao.find(params[:id])
    end

    def selecao_params
      params.require(:selecao).permit(:nome, :pontos, :jogos, :vitorias, :derrotas, :empates, :logo, :grupo_id)
    end

    def logos_disponiveis
      @logos = Dir.glob(
        Rails.root.join('app/assets/images/selecoes/*')
      ).map { |path| File.basename(path) }
    end

    def load_grupos
      @grupos = Grupo.order(:nome)
    end
end
