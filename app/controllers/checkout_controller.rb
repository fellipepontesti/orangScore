class CheckoutController < ApplicationController
  before_action :authenticate_user!

  protect_from_forgery except: :stripe

  def stripe
    cobranca = Cobrancas::Create.call(
      user: current_user,
      plano: params[:plano],
      payment_method: params[:payment_method],
      gateway: :stripe
    )

    session = Stripe::CreateCheckout.call(
      cobranca: cobranca,
      success_url: "#{request.base_url}/checkout/sucesso",
      cancel_url: planos_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def mercado_pago_pix
    cobranca = nil

    cobranca = Cobrancas::Create.call(
      user: current_user,
      plano: params[:plano],
      payment_method: :pix,
      gateway: :mercado_pago
    )

    MercadoPago::CreatePixPreference.call(
      cobranca: cobranca,
      notification_url: mercado_pago_webhook_url,
      success_url: checkout_sucesso_url,
      failure_url: planos_url,
      pending_url: checkout_pix_url(cobranca)
    )

    redirect_to checkout_pix_path(cobranca)
  rescue MercadoPago::ApiError, MercadoPago::ConfigurationError => e
    Rails.logger.error "Erro ao criar Pix Mercado Pago: #{e.message}"
    cobranca&.destroy if cobranca&.gateway_cobranca_id.blank?

    redirect_to planos_path, alert: e.user_message
  rescue => e
    Rails.logger.error "Erro ao criar Pix Mercado Pago: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    cobranca&.destroy if cobranca&.gateway_cobranca_id.blank?

    redirect_to planos_path, alert: "Não foi possível gerar o Pix. Tente novamente em instantes."
  end

  def pix
    @cobranca = current_user.cobrancas.find(params[:id])
  end

  def sucesso
  end
end
