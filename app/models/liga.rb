class Liga < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  before_create :generate_invite_token

  has_many :liga_membros, dependent: :destroy
  has_many :users, through: :liga_membros

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
  
  private

  def generate_invite_token
    self.invite_token = SecureRandom.hex(10)
  end
end
