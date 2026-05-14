class Cobranca < ApplicationRecord
  belongs_to :user

  enum status: {
    pendente: 0,
    pago: 1,
    expirado: 2,
    cancelado: 3,
    falhou: 4
  }

  enum gateway: {
    stripe: "stripe",
    woovi: "woovi",
    mercado_pago: "mercado_pago"
  }

  enum payment_method: {
    card: "card",
    pix: "pix"
  }
end
