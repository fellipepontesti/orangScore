class Assinatura < ApplicationRecord
  include HasPublicUuid
  self.table_name = 'assinaturas'

  belongs_to :usuario,
             class_name: 'User'

  after_save :check_premium_achievement, if: :saved_change_to_plano?

  def check_premium_achievement
    if premium?
      Users::AwardAchievements.award(usuario, 'premium_user')
    end
  end

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
