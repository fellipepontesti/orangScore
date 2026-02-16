class SelecoesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_grupos, only: %i[new create edit update]
  before_action :logos_disponiveis, only: %i[new create edit update]
  before_action :set_selecao, only: %i[ show edit update destroy ]

  def index
    @selecoes = Selecao.all
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
    @selecao = Selecao.new(selecao_params)

    if Selecao.where(grupo_id: selecao_params[:grupo_id]).count >= 4
      flash.now[:alert] = "Grupo cheio!"
      render :new, status: :unprocessable_entity
      return
    end

    respond_to do |format|
      if @selecao.save
        format.html { redirect_to @selecao, notice: "Seleção criada com sucesso!" }
        format.json { render :show, status: :created, location: @selecao }
      else
        puts @selecao.errors
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @selecao.update(selecao_params)
        format.html { redirect_to @selecao, notice: "Seleção editada com sucesso!", status: :see_other }
        format.json { render :show, status: :ok, location: @selecao }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @selecao.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @selecao.destroy!

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
