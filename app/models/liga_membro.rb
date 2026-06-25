class LigaMembro < ApplicationRecord
  include HasPublicUuid
  belongs_to :liga
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }
  enum :status, { invited: 0, accepted: 1, pending_deletion: 2 }

  after_save :check_achievements, if: -> { accepted? && saved_change_to_status? }

  def pontos_na_liga
    if liga.pontuacao_zerada?
      user.user_points.where("created_at >= ?", created_at).sum(:pontos)
    else
      user.user_points.sum(:pontos)
    end
  end

  def palpites_na_liga_count
    user.palpites.count
  end

  private

  def check_achievements
    Users::AwardAchievements.check_socializacao(liga.owner)
    Users::AwardAchievements.check_liga_cheia(liga.owner)

    liga.users.each do |u|
      Users::AwardAchievements.check_liga_cheia(u)
    end
  end
end
