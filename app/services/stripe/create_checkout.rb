module Stripe
  class CreateCheckout
    def self.call(cobranca:, success_url:, cancel_url:)
      session = ::Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        mode: "payment",
        customer_email: cobranca.user.email,

        line_items: [
          {
            price_data: {
              currency: "brl",
              product_data: {
                name: "Plano #{cobranca.plano.capitalize}"
              },
              unit_amount: cobranca.valor
            },
            quantity: 1
          }
        ],

        metadata: {
          cobranca_id: cobranca.id
        },

        success_url: success_url,
        cancel_url: cancel_url
      )

      cobranca.update!(
        gateway_cobranca_id: session.id,
        gateway_checkout_url: session.url
      )

      session
    end
  end
end