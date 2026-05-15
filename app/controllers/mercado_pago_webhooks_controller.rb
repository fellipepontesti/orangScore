class MercadoPagoWebhooksController < ApplicationController
  skip_forgery_protection
  wrap_parameters false
  skip_before_action :authenticate_user!
  skip_before_action :check_terms_acceptance

  def create
    # O Mercado Pago manda o ID real dentro de 'data' se for do tipo novo (V1/V2).
    # Se não tiver 'data', ele manda no 'id' (tipo antigo).
    payment_id = params.dig(:data, :id) || params[:id]
    topic = params[:type] || params[:topic]

    Rails.logger.info "[Webhook MP] Notificação recebida. Topic: #{topic}, Resource ID: #{payment_id}"
    Rails.logger.info "[Webhook MP] Params: #{params.to_unsafe_h.to_json}"

    # Se não for sobre pagamento, só respondemos OK para o MP parar de encher o saco
    unless topic == "payment"
      return head :ok
    end

    return head :ok if payment_id.blank?

    # Busca os detalhes do pagamento no MP
    payment = MercadoPago::Client.new.payment(payment_id)
    
    if payment
      MercadoPago::ProcessarPagamento.new(payment: payment).call
    end

    head :ok
  rescue => e
    Rails.logger.error "Erro no Webhook Mercado Pago: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    head :internal_server_error
  end
end
