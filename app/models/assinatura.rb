class Assinatura < ApplicationRecord
  include HasPublicUuid
  self.table_name = 'assinaturas'

  belongs_to :usuario,
             class_name: 'User'

  enum :plano, {
    basic: 0,
    plus: 1,
    premium: 2,
    doacao: 3,
    semi_plus: 4
  }

  def limite_ligas
    case plano
    when 'premium'
      999999
    else
      1
    end
  end

  def limite_usuarios_por_liga
    case plano
    when 'premium'
      999999
    else
      15
    end
  end
end
