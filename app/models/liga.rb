class Liga < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  before_create :generate_invite_token

  has_many :liga_membros, dependent: :destroy
  has_many :users, through: :liga_membros

  validates :nome, presence: true
  
  private

  def generate_invite_token
    self.invite_token = SecureRandom.hex(10)
  end
end
