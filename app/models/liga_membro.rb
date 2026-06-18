class LigaMembro < ApplicationRecord
  include HasPublicUuid
  belongs_to :liga
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }
  enum :status, { invited: 0, accepted: 1, pending_deletion: 2 }

  def pontos_na_liga
    if liga.pontuacao_zerada?
      user.user_points.where("created_at >= ?", created_at).sum(:pontos)
    else
      user.user_points.sum(:pontos)
    end
  end

  def palpites_na_liga_count
    if liga.pontuacao_zerada?
      user.palpites.where("created_at >= ?", created_at).count
    else
      user.palpites.count
    end
  end
end
