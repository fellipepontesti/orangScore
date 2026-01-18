class GruposController < ApplicationController
  before_action :set_grupo, only: %i[ show edit update destroy ]

  def index
    @grupos = Grupo.includes(:selecoes)
      .includes(selecoes: :grupo)
      .order(:nome)
      .paginate(page: params[:page], per_page: 1)
    
    @grupo_labels = Grupo.order(:nome).pluck(:nome)
  end

  def show
    @selecoes = @grupo.selecoes.order(:nome)
  end

  def new
    @grupo = Grupo.new
  end

  def edit
  end

  def create
    @grupo = Grupo.new(grupo_params)

    respond_to do |format|
      if @grupo.save
        format.html { redirect_to @grupo, notice: "Grupo criado com sucesso!." }
        format.json { render :show, status: :created, location: @grupo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @grupo.update(grupo_params)
        format.html { redirect_to @grupo, notice: "Grupo editado com sucesso!.", status: :see_other }
        format.json { render :show, status: :ok, location: @grupo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @grupo.destroy!

    respond_to do |format|
      format.html { redirect_to grupos_path, notice: "Grupo excluído com sucesso!.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_grupo
      @grupo = Grupo.find(params[:id])
    end

    def grupo_params
      params.require(:grupo).permit(:nome, :rodadas)
    end
end
