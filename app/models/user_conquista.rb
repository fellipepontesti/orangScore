class UserConquista < ApplicationRecord
  include HasPublicUuid
  self.table_name = 'user_conquistas'

  belongs_to :user
  belongs_to :conquista
  belongs_to :jogo, optional: true

  validates :user_id, uniqueness: { scope: :conquista_id, message: "já possui esta conquista" }
  validate :valida_limite_destacados, if: :destacada?

  private

  def valida_limite_destacados
    limite = user.premium? ? 3 : 1
    outros_destacados = user.user_conquistas.where(destacada: true)
    outros_destacados = outros_destacados.where.not(id: id) if persisted?
    
    if outros_destacados.count >= limite
      errors.add(:destacada, "Limite de conquistas em destaque atingido (#{limite} para o seu plano).")
    end
  end
end
