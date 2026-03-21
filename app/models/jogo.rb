class Jogo < ApplicationRecord
  belongs_to :mandante, class_name: 'Selecao', optional: true
  belongs_to :visitante, class_name: 'Selecao', optional: true
  belongs_to :grupo, optional: true
  has_many :palpites, dependent: :destroy

  enum :tipo, { grupo: 0, segunda_fase: 1, oitavas: 2, quartas: 3, semi: 4, final: 5 }
  enum :status, { programado: 0, em_andamento: 1, finalizado: 2, times_a_definir: 3 }

  validates :data, presence: true
  validates :tipo, presence: true
  validates :mandante_id, presence: true, unless: :definir?
  validates :visitante_id, presence: true, unless: :definir?

  validate :times_diferentes, unless: :definir?
  validate :definir_apenas_no_mata_mata

  ESTADIOS_2026 = [
    "MetLife Stadium (New York/New Jersey, EUA)",
    "SoFi Stadium (Los Angeles, EUA)",
    "AT&T Stadium (Dallas, EUA)",
    "NRG Stadium (Houston, EUA)",
    "Mercedes-Benz Stadium (Atlanta, EUA)",
    "Hard Rock Stadium (Miami, EUA)",
    "Lincoln Financial Field (Philadelphia, EUA)",
    "Lumen Field (Seattle, EUA)",
    "Levi's Stadium (San Francisco Bay Area, EUA)",
    "Gillette Stadium (Boston, EUA)",
    "Arrowhead Stadium (Kansas City, EUA)",
    "BC Place (Vancouver, Canadá)",
    "BMO Field (Toronto, Canadá)",
    "Estadio Azteca (Cidade do México, México)",
    "Estadio BBVA (Monterrey, México)",
    "Estadio Akron (Guadalajara, México)"
  ]

  private

  def times_diferentes
    return if mandante_id.blank? || visitante_id.blank?
    return if mandante_id != visitante_id

    errors.add(:visitante_id, 'deve ser diferente do mandante')
  end

  def definir_apenas_no_mata_mata
    return unless definir?
    return unless grupo?

    errors.add(:definir, 'só pode ser marcado em jogos do mata-mata')
  end
end