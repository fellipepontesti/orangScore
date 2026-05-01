class Palpite < ApplicationRecord
  belongs_to :user
  belongs_to :jogo

  validates :gols_casa, presence: true
  validates :gols_fora, presence: true
  validate :jogo_deve_estar_definido

  private

  def jogo_deve_estar_definido
    if jogo.present? && (jogo.times_a_definir? || jogo.definir?)
      errors.add(:base, "Não é possível palpitar em jogos com seleções a definir.")
    end
  end
end
