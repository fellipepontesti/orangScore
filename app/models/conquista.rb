class Conquista < ApplicationRecord
  include HasPublicUuid
  self.table_name = 'conquistas'

  has_many :user_conquistas, dependent: :destroy
  has_many :users, through: :user_conquistas

  validates :nome, :descricao, :slug, :icon, :cor, presence: true
  validates :slug, uniqueness: true
end
