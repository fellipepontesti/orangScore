class Jogo < ApplicationRecord
  include HasPublicUuid

  belongs_to :mandante, class_name: 'Selecao', optional: true
  belongs_to :visitante, class_name: 'Selecao', optional: true
  belongs_to :grupo, optional: true
  belongs_to :vencedor_penaltis, class_name: 'Selecao', optional: true
  has_many :palpites, dependent: :destroy
  has_many :user_points, dependent: :destroy
  has_one :informacao_jogo, class_name: 'InformacaoJogo', dependent: :destroy

  enum :tipo, { grupo: 0, segunda_fase: 1, oitavas: 2, quartas: 3, semi: 4, final: 5, terceiro_lugar: 6 }
  enum :status, { programado: 0, em_andamento: 1, finalizado: 2, times_a_definir: 3, suspenso: 4 }

  def palpitavel?
    programado?
  end

  before_validation :ajustar_definicao_e_status, if: :pode_ajustar_definicao_e_status?
  before_validation :definir_vencedor_penaltis, if: :tem_placar_penaltis?

  validates :data, presence: true
  validates :tipo, presence: true
  validates :mandante_id, presence: true, unless: :definir?
  validates :visitante_id, presence: true, unless: :definir?

  validate :times_diferentes, unless: :definir?
  validate :definir_apenas_no_mata_mata
  validate :placar_penaltis_diferente, if: :tem_placar_penaltis?

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

  after_save :recalcular_estatisticas_selecoes, if: :saved_changes_para_grupo?
  after_save :atualizar_chaves_torneio, if: :saved_changes_necessitam_atualizar_chaves?
  after_destroy :recalcular_estatisticas_selecoes_apos_destruicao, if: :grupo?

  private

  def saved_changes_necessitam_atualizar_chaves?
    # Dispara se o status mudou (por exemplo, finalizou agora)
    # OU se é um jogo de grupo finalizado e mudaram os gols (placar atualizado)
    saved_change_to_status? || (grupo? && finalizado? && (saved_change_to_gols_mandante? || saved_change_to_gols_visitante?))
  end

  def saved_changes_para_grupo?
    grupo? && (saved_change_to_gols_mandante? || saved_change_to_gols_visitante? || saved_change_to_status? || saved_change_to_mandante_id? || saved_change_to_visitante_id?)
  end

  def recalcular_estatisticas_selecoes
    if saved_change_to_mandante_id? && mandante_id_before_last_save
      antigo_mandante = Selecao.find_by(id: mandante_id_before_last_save)
      Selecoes::RecalcularEstatisticas.recalcular(antigo_mandante) if antigo_mandante
    end
    if saved_change_to_visitante_id? && visitante_id_before_last_save
      antigo_visitante = Selecao.find_by(id: visitante_id_before_last_save)
      Selecoes::RecalcularEstatisticas.recalcular(antigo_visitante) if antigo_visitante
    end

    Selecoes::RecalcularEstatisticas.recalcular(mandante) if mandante
    Selecoes::RecalcularEstatisticas.recalcular(visitante) if visitante
  end

  def recalcular_estatisticas_selecoes_apos_destruicao
    Selecoes::RecalcularEstatisticas.recalcular(mandante) if mandante
    Selecoes::RecalcularEstatisticas.recalcular(visitante) if visitante
  end

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

  def atualizar_chaves_torneio
    return unless finalizado?

    if grupo?
      # Se a seleção mandante ou visitante ainda tem jogo não finalizado na fase de grupos, não faz nada
      mandante_tem_jogos = Jogo.where(grupo_id: grupo_id)
                               .where.not(status: :finalizado)
                               .where("mandante_id = ? OR visitante_id = ?", mandante_id, mandante_id)
                               .exists?

      visitante_tem_jogos = Jogo.where(grupo_id: grupo_id)
                                .where.not(status: :finalizado)
                                .where("mandante_id = ? OR visitante_id = ?", visitante_id, visitante_id)
                                .exists?

      return if mandante_tem_jogos || visitante_tem_jogos
    end

    Jogos::BracketManager.atualizar
  end

  def pode_ajustar_definicao_e_status?
    mandante_id.present? && visitante_id.present? && (definir? || times_a_definir?)
  end

  def ajustar_definicao_e_status
    self.definir = false
    self.status = :programado if times_a_definir?
  end

  def tem_placar_penaltis?
    gols_penaltis_mandante.present? && gols_penaltis_visitante.present?
  end

  def definir_vencedor_penaltis
    if gols_penaltis_mandante > gols_penaltis_visitante
      self.vencedor_penaltis_id = mandante_id
    elsif gols_penaltis_visitante > gols_penaltis_mandante
      self.vencedor_penaltis_id = visitante_id
    end
  end

  def placar_penaltis_diferente
    if gols_penaltis_mandante == gols_penaltis_visitante
      errors.add(:base, "A disputa de pênaltis não pode terminar empatada.")
    end
  end
end
