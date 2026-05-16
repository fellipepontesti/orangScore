class PagamentosController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_root!

  def index
    @pagamentos = Pagamento.includes(:user).order(created_at: :desc).paginate(page: params[:page], per_page: 20)
    
    @total_bruto = Pagamento.where(status: :pago).sum(:valor) / 100.0
    @total_mes = Pagamento.where(status: :pago, created_at: Time.current.beginning_of_month..Time.current.end_of_month).sum(:valor) / 100.0
    @qtd_transacoes = Pagamento.where(status: :pago).count
  end
end
