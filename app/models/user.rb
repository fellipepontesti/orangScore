class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :ligas, foreign_key: :owner_id
  has_many :liga_membros
  has_many :palpites, dependent: :destroy
  has_many :notificacoes, dependent: :destroy
  has_many :ligas_participadas, through: :liga_membros, source: :liga
  belongs_to :selecao_favorita, class_name: 'Selecao', optional: true
  belongs_to :selecao
  has_many :user_points, dependent: :destroy
  has_many :pagamentos
  has_many :cobrancas

  has_one :assinatura,
        class_name: 'Assinatura',
        foreign_key: 'usuario_id',
        dependent: :destroy


  after_create :criar_assinatura_padrao

  def total_pontos
    user_points.sum(:pontos)
  end

  validates :name, 
            :selecao_id,
            :logo_selecao,
            presence: true
  
  validates :terms_of_service, acceptance: true
        
  validates :password,
  format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}\z/,
    message: 'deve ter no mínimo 8 caracteres, incluindo maiúscula, minúscula, número e símbolo'
  },
  if: :password_required?

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

  def premium?
    assinatura.present? && assinatura.premium?
  end

  def plus?
    assinatura.present? && assinatura.plus?
  end

  def basic?
    assinatura.present? && assinatura.basic?
  end

  def limite_ligas
    assinatura.limite_ligas
  end

  def atingiu_limite_de_ligas?
    ligas.count >= limite_ligas
  end

  def limite_usuarios_por_liga
    assinatura.limite_usuarios_por_liga
  end

  before_validation :set_logo_selecao, on: :create

  private

  def set_logo_selecao
    return if selecao.nil?

    self.logo_selecao = selecao.logo
  end

  def criar_assinatura_padrao
    create_assinatura!(
      plano: :basic
    )
  end
end
