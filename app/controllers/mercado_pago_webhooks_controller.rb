class MercadoPagoWebhooksController < ApplicationController
  skip_forgery_protection
  wrap_parameters false

  def create
    # O Mercado Pago manda o ID no params ou no payload.
    payment_id = params[:id] || params.dig(:data, :id)
    topic = params[:topic] || params[:type]

    Rails.logger.info "[Webhook MP] Recebido: Topic: #{topic}, ID: #{payment_id}"

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
