class Palpite < ApplicationRecord
  belongs_to :user
  belongs_to :jogo

  validates :gols_casa, presence: true
  validates :gols_fora, presence: true
end
