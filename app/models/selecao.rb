class Selecao < ApplicationRecord
  belongs_to :grupo, optional: true
  has_many :jogos_como_mandante,
           class_name: 'Jogo',
           foreign_key: :mandante_id,
           dependent: :destroy

  has_many :jogos_como_visitante,
           class_name: 'Jogo',
           foreign_key: :visitante_id,
           dependent: :destroy

  validates :nome, presence: true, uniqueness: {
    message: 'já está sendo utilizado por outra seleção'
  }

  validates :logo, presence: true, uniqueness: {
    message: 'já está sendo utilizada por outra seleção'
  }
  
  validates :nome, presence: true
  scope :ordenadas, -> { order(pontos: :desc, nome: :asc) }
end
