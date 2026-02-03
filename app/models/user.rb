class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :ligas, foreign_key: :owner_id
  has_many :liga_membros
  has_many :ligas_participadas, through: :liga_membros, source: :liga
  belongs_to :selecao_favorita, class_name: 'Selecao', optional: true
  belongs_to :selecao

  validates :name, 
            :selecao_id,
            :logo_selecao,
            presence: true

  enum :tipo, { normal_user: 0, root: 1 }

  before_validation :set_logo_selecao, on: :create

  private

  def set_logo_selecao
    return if selecao.nil?

    self.logo_selecao = selecao.logo
  end
end
