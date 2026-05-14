class Pagamento < ApplicationRecord
  belongs_to :user
  belongs_to :cobranca

  enum status: {
    pendente: 0,
    processando: 1,
    pago: 2,
    falhou: 3,
    estornado: 4
  }

  validates :valor, presence: true
  validates :status, presence: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :mercado_pago_payment_id, uniqueness: true, allow_nil: true

  def pago?
    status == "pago"
  end

  def pendente?
    status == "pendente"
  end

  def falhou?
    status == "falhou"
  end

  def valor_em_reais
    valor.to_f / 100
  end

  def liberar_plano!(plano:)
    transaction do
      update!(
        status: :pago,
        plano: plano,
        pago_em: Time.current
      )

      user.update!(
        plano_ativo: true,
        ultimo_pagamento_em: Time.current
      )
    end
  end

  def marcar_falha!
    update!(status: :falhou)
  end
end