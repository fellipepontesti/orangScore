class Jogo < ApplicationRecord
  belongs_to :mandante, class_name: 'Selecao'
  belongs_to :visitante, class_name: 'Selecao'
  belongs_to :grupo, optional: true

  enum :tipo, { grupo: 0, mata_mata: 1 }
end
