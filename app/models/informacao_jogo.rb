class InformacaoJogo < ApplicationRecord
  self.table_name = "informacao_jogos"

  belongs_to :jogo

  validates :dados, presence: true
end
