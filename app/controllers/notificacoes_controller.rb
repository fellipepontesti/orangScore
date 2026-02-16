class NotificacoesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notificacao, only: %i[ show edit update destroy ]

  def index
    @notificacoes = Notificacao.where(user_id: current_user.id)
  end

  def show
    @notificacao = Notificacao.find(params[:id])

    @notificacao.read!
  end

  def new
    # @notificacao = Notificacao.new
  end

  # GET /notificacoes/1/edit
  def edit
  end

  # POST /notificacoes or /notificacoes.json
  def create
    @notificacao = Notificacao.new(notificacao_params)

    respond_to do |format|
      if @notificacao.save
        format.html { redirect_to @notificacao, notice: "Notificacao was successfully created." }
        format.json { render :show, status: :created, location: @notificacao }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notificacoes/1 or /notificacoes/1.json
  def update
    respond_to do |format|
      if @notificacao.update(notificacao_params)
        format.html { redirect_to @notificacao, notice: "Notificacao was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @notificacao }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notificacoes/1 or /notificacoes/1.json
  def destroy
    @notificacao.destroy!

    respond_to do |format|
      format.html { redirect_to notificacoes_path, notice: "Notificacao was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notificacao
      @notificacao = Notificacao.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def notificacao_params
      params.require(:notificacao).permit(:user_id, :sender_id, :tipo, :texto, :status)
    end
end
