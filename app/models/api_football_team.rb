class ApiFootballTeam < ApplicationRecord
  belongs_to :selecao, optional: true

  validates :api_id, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordenadas, -> { order(:country, :name) }
end
