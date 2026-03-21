class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :ligas, foreign_key: :owner_id
  has_many :liga_membros
  has_many :palpites, dependent: :destroy
  has_many :ligas_participadas, through: :liga_membros, source: :liga
  belongs_to :selecao_favorita, class_name: 'Selecao', optional: true
  belongs_to :selecao

  validates :name, 
            :selecao_id,
            :logo_selecao,
            presence: true

  enum :tipo, { normal_user: 0, root: 1 }

  def generate_password_recovery!
    token = SecureRandom.urlsafe_base64(32)

    update!(
      password_recovery_token: token,
      password_recovery_sent_at: Time.current
    )

    token
  end

  def password_recovery_expired?
    password_recovery_sent_at < 2.hours.ago
  end

  def clear_password_recovery!
    update!(
      password_recovery_token: nil,
      password_recovery_sent_at: nil
    )
  end

  before_validation :set_logo_selecao, on: :create

  private

  def set_logo_selecao
    return if selecao.nil?

    self.logo_selecao = selecao.logo
  end
end
