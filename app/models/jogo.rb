class Jogo < ApplicationRecord
  belongs_to :mandante, class_name: 'Selecao'
  belongs_to :visitante, class_name: 'Selecao'
  belongs_to :grupo, optional: true

  enum :tipo, { grupo: 0, oitavas: 1, quartas: 2, semi: 3, final: 4 }
end
