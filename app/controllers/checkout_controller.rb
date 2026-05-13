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
end