class MercadoPagoWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :set_request_format

  def create
    # O Mercado Pago manda o ID no params ou no payload.
    payment_id = params[:id] || params.dig(:data, :id)
    topic = params[:topic] || params[:type]

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
  rescue JSON::ParserError => e
    Rails.logger.error "Payload inválido no Webhook Mercado Pago: #{e.message}"
    head :bad_request
  rescue => e
    Rails.logger.error "Erro no Webhook Mercado Pago: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    head :internal_server_error
  end

  private

  def parsed_payload
    JSON.parse(request.body.read)
  end

  def valid_signature?(payment_id)
    MercadoPago::WebhookSignature.valid?(
      data_id: payment_id,
      request_id: request.headers["x-request-id"],
      signature: request.headers["x-signature"],
      secret: MercadoPago::Config.webhook_secret
    )
  end

  def set_request_format
    request.format = :json
  end
end
