class Liga < ApplicationRecord
  belongs_to :owner, class_name: 'User'

  has_many :liga_membros, dependent: :destroy
  has_many :users, through: :liga_membros

  validates :nome, presence: true
end
