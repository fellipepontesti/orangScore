class Liga < ApplicationRecord
  include HasPublicUuid

  belongs_to :owner, class_name: 'User'
  before_create :generate_invite_token

  has_many :liga_membros, dependent: :destroy
  has_many :users, through: :liga_membros

  scope :com_total_pontos, -> {
    joins("LEFT JOIN (
      SELECT lm.liga_id, COALESCE(SUM(CASE WHEN l.pontuacao_zerada THEN (CASE WHEN up.created_at >= lm.created_at THEN up.pontos ELSE 0 END) ELSE up.pontos END), 0) as pontos_totais
      FROM liga_membros lm
      JOIN ligas l ON l.id = lm.liga_id
      JOIN user_points up ON up.user_id = lm.user_id
      WHERE lm.status = 1
      GROUP BY lm.liga_id
    ) pontuacoes_ligas ON pontuacoes_ligas.liga_id = ligas.id")
    .select("ligas.*, COALESCE(pontuacoes_ligas.pontos_totais, 0) AS total_pontos_liga")
  }

  scope :ordenadas_por_pontos, -> {
    com_total_pontos.order("total_pontos_liga DESC, ligas.nome ASC")
  }

  validates :nome, presence: true

  def limite_participantes
    owner.limite_usuarios_por_liga
  end

  def total_participantes
    liga_membros.count
  end

  def atingiu_limite_de_participantes?
    total_participantes >= limite_participantes
  end

  def vagas_restantes
    limite_participantes - total_participantes
  end

  def total_pontos_liga
    if respond_to?(:total_pontos_liga) && read_attribute(:total_pontos_liga).present?
      read_attribute(:total_pontos_liga)
    else
      if pontuacao_zerada?
        UserPoint.joins(user: :liga_membros)
                 .where(liga_membros: { liga_id: id, status: :accepted })
                 .where("user_points.created_at >= liga_membros.created_at")
                 .sum(:pontos)
      else
        UserPoint.joins(user: :liga_membros)
                 .where(liga_membros: { liga_id: id, status: :accepted })
                 .sum(:pontos)
      end
    end
  end
  
  private

  def generate_invite_token
    self.invite_token = SecureRandom.hex(10)
  end
end
