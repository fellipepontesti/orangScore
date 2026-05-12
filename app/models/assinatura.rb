class Assinatura < ApplicationRecord
  self.table_name = 'assinaturas'

  belongs_to :usuario,
             class_name: 'User'

  enum :plano, {
    basic: 0,
    plus: 1,
    premium: 2
  }

  def limite_ligas
    case plano
    when 'basic'
      1
    when 'plus'
      5
    when 'premium'
      999999
    end
  end

  def limite_usuarios_por_liga
    case plano
    when 'basic'
      5
    when 'plus'
      25
    when 'premium'
      999999
    end
  end
end