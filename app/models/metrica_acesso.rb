class MetricaAcesso < ApplicationRecord
  self.table_name = "metricas_acessos"
  validates :key, presence: true, uniqueness: true
  validates :nome, presence: true

  def self.registrar(key, nome)
    metrica = find_or_initialize_by(key: key)
    metrica.nome = nome
    metrica.acessos = (metrica.acessos || 0) + 1
    metrica.save
  end
end
