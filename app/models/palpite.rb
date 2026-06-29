class Palpite < ApplicationRecord
  include HasPublicUuid
  belongs_to :user
  belongs_to :jogo
  belongs_to :vencedor_penaltis, class_name: 'Selecao', optional: true

  validates :gols_casa, presence: true
  validates :gols_fora, presence: true
  validate :jogo_deve_estar_definido
  validate :placar_penaltis_diferente, if: :tem_placar_penaltis?

  before_validation :definir_vencedor_penaltis, if: :tem_placar_penaltis?

  private

  def jogo_deve_estar_definido
    if jogo.present? && (jogo.times_a_definir? || jogo.definir?)
      errors.add(:base, "Não é possível palpitar em jogos com seleções a definir.")
    end
  end

  def tem_placar_penaltis?
    gols_penaltis_casa.present? && gols_penaltis_fora.present?
  end

  def definir_vencedor_penaltis
    return unless jogo.present?
    
    if gols_penaltis_casa > gols_penaltis_fora
      self.vencedor_penaltis_id = jogo.mandante_id
    elsif gols_penaltis_fora > gols_penaltis_casa
      self.vencedor_penaltis_id = jogo.visitante_id
    end
  end

  def placar_penaltis_diferente
    if gols_penaltis_casa == gols_penaltis_fora
      errors.add(:base, "A disputa de pênaltis não pode terminar empatada.")
    end
  end
end
