class Grupo < ApplicationRecord
  has_many :selecoes, dependent: :destroy

  validates :nome, presence: true
end
