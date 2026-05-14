class MercadoPagoWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :set_request_format

  def create
    payload = parsed_payload
    payment_id = payload.dig("data", "id") || params.dig(:data, :id) || params["data.id"]
    return head :bad_request if payment_id.blank?

    unless valid_signature?(payment_id)
      Rails.logger.warn "Falha na verificação do Webhook Mercado Pago"
      return head :bad_request
    end

    return head :ok unless payload["type"] == "payment" || payload["action"].to_s.start_with?("payment.")

    payment = MercadoPago::Client.new.payment(payment_id)
    MercadoPago::ProcessarPagamento.new(payment: payment).call

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
