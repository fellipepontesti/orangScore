class Jogador < ApplicationRecord
  include HasPublicUuid
  self.table_name = "jogadores"

  belongs_to :selecao

  validates :nome, presence: true

  # Mapeamento útil de posições para português
  def posicao_pt
    case posicao
    when 'GK', 'Goalkeeper'
      'Goleiro'
    when 'DF', 'Defender'
      'Defensor'
    when 'MF', 'Midfielder'
      'Meio-campista'
    when 'FW', 'Forward'
      'Atacante'
    else
      posicao
    end
  end
end
