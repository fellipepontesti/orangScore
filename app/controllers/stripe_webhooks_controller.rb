class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    event = Stripe::Webhook.construct_event(
      payload,
      sig_header,
      ENV["STRIPE_WEBHOOK_SECRET"]
    )

    if event.type == "checkout.session.completed"
      Stripe::ProcessarPagamentoCheckout.new(session: event.data.object).call
    end

    head :ok
  rescue JSON::ParserError
    render json: { error: "payload invalido" }, status: :bad_request
  rescue Stripe::SignatureVerificationError
    render json: { error: "assinatura invalida" }, status: :bad_request
  end
end