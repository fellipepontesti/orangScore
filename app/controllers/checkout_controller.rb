class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :validar_upgrade!, only: [:stripe, :mercado_pago_pix]

  protect_from_forgery except: :stripe

  def stripe
    valor_em_centavos = nil
    if params[:plano] == "doacao" && params[:valor].present?
      valor_em_centavos = (params[:valor].gsub(",", ".").to_f * 100).to_i
    end

    cobranca = Cobrancas::Create.call(
      user: current_user,
      plano: params[:plano],
      payment_method: params[:payment_method],
      gateway: :stripe,
      valor_customizado: valor_em_centavos
    )

    session = Stripe::CreateCheckout.call(
      cobranca: cobranca,
      success_url: "#{request.base_url}/checkout/sucesso",
      cancel_url: planos_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def mercado_pago_pix
    valor_em_centavos = nil
    if params[:plano] == "doacao" && params[:valor].present?
      # Converte "10,50" ou "10.50" para 1050 centavos
      valor_em_centavos = (params[:valor].gsub(",", ".").to_f * 100).to_i
    end

    @cobranca = Cobrancas::Create.call(
      user: current_user,
      plano: params[:plano],
      gateway: :mercado_pago,
      payment_method: :pix,
      valor_customizado: valor_em_centavos
    )

    notification_url = "#{ENV["WEBHOOK_HOST"].gsub(/\/$/, '')}/mercado_pago/webhook"

    MercadoPago::CreatePixPreference.call(
      cobranca: @cobranca,
      notification_url: notification_url,
      success_url: checkout_sucesso_url,
      failure_url: planos_url,
      pending_url: checkout_pix_url(@cobranca)
    )

    redirect_to @cobranca.gateway_checkout_url, allow_other_host: true, status: :see_other
  rescue MercadoPago::ApiError => e
    Rails.logger.error "Erro ao criar Pix Mercado Pago: #{e.message}"
    @cobranca&.destroy if @cobranca&.gateway_cobranca_id.blank?
    redirect_to planos_path, alert: e.user_message, status: :see_other
  rescue => e
    Rails.logger.error "Erro ao criar Pix Mercado Pago: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    @cobranca&.destroy if @cobranca&.gateway_cobranca_id.blank?
    redirect_to planos_path, alert: "Não foi possível gerar o Pix. Tente novamente em instantes.", status: :see_other
  end

  def pix
    @cobranca = current_user.cobrancas.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: { status: @cobranca.status } }
    end
  end

  def sucesso
  end

  private

  def validar_upgrade!
    return if params[:plano] == "doacao"
    
    plano_solicitado = params[:plano].to_s
    nivel_solicitado = Assinatura.planos[plano_solicitado] || 0
    nivel_atual = current_user.assinatura.plano_before_type_cast

    if nivel_solicitado <= nivel_atual
      redirect_to planos_path, alert: "Você já possui este plano ou um superior. O downgrade não é permitido."
    end
  end
end
