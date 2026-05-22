class Grupo < ApplicationRecord
  include HasPublicUuid

  has_many :selecoes, dependent: :destroy

  validates :nome, presence: true
end
