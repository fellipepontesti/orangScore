class User < ApplicationRecord
  include HasPublicUuid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth, ref_id = nil)
    user = User.find_by(email: auth.info.email)

    if user
      if user.provider.blank? || user.uid.blank?
        user.update(provider: auth.provider, uid: auth.uid)
      end
      user
    else
      where(provider: auth.provider, uid: auth.uid).first_or_create do |new_user|
        new_user.email = auth.info.email
        new_user.password = Devise.friendly_token[0, 20]
        new_user.name = auth.info.name
        new_user.selecao_id = Selecao.find_by(nome: 'A definir')&.id || Selecao.first&.id
        new_user.terms_of_service = '1'
        new_user.referred_by_id = ref_id if ref_id.present?
        new_user.skip_confirmation!
      end
    end
  end

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


  attr_accessor :terms_of_service

  before_create :set_terms_accepted_at
  after_create :criar_assinatura_padrao

  def total_pontos
    user_points.sum(:pontos)
  end

  validates :name, 
            :selecao_id,
            :logo_selecao,
            presence: true

  validates :name,
            format: {
              with: /\A[\p{L}\s]+\z/,
              message: "deve conter apenas letras e espaços"
            },
            allow_blank: true
  
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

  def selecao_editavel?
    primeiro_jogo_em = Jogo.minimum(:data)

    primeiro_jogo_em.blank? || Time.current < primeiro_jogo_em
  end

  def count_referral_for_liga!(liga)
    return unless referred_by_id.present?
    return if referral_counted_at.present?
    return if referred_by_id == id
    return unless liga.liga_membros.accepted.exists?(user_id: referred_by_id)

    with_lock do
      return if referral_counted_at.present?

      referrer = User.find_by(id: referred_by_id)
      return unless referrer

      referrer.increment!(:referrals_count)
      update!(referral_counted_at: Time.current)

      reward_referrer_if_needed!(referrer)
    end
  end

  before_validation :set_logo_selecao, if: :will_save_change_to_selecao_id?

  private

  def set_logo_selecao
    return if selecao.nil?

    self.logo_selecao = selecao.logo
  end

  def set_terms_accepted_at
    self.terms_accepted_at = Time.current
  end

  def criar_assinatura_padrao
    create_assinatura!(
      plano: :basic
    )
  end

  def reward_referrer_if_needed!(referrer)
    if referrer.referrals_count == 5
      referrer.assinatura&.update!(plano: :semi_plus)
      Notificacao.create!(
        user: referrer,
        texto: "Parabéns! Você indicou 5 amigos e agora tem o plano Semi-Plus ativo. Aproveite para criar ligas com até 10 pessoas!",
        tipo: :info,
        status: :unread
      )
    end
  end
end
