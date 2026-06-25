class User < ApplicationRecord
  include HasPublicUuid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :trackable,
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
  has_many :user_conquistas, dependent: :destroy
  has_many :conquistas, through: :user_conquistas

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
  validate :name_must_be_appropriate
        
  validates :password,
  format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}\z/,
    message: 'deve ter no mínimo 8 caracteres, incluindo maiúscula, minúscula, número e símbolo'
  },
  if: :password_required?

  enum :tipo, { normal_user: 0, root: 1, semi_root: 2 }

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

  def online?
    last_seen_at.present? && last_seen_at > 5.minutes.ago
  end

  def premium?
    assinatura.present? && assinatura.premium?
  end

  def basic?
    assinatura.present? && assinatura.basic?
  end

  def limite_ligas
    assinatura.present? ? assinatura.limite_ligas : 1
  end

  def atingiu_limite_de_ligas?
    ligas.count >= limite_ligas
  end

  def limite_usuarios_por_liga
    assinatura.present? ? assinatura.limite_usuarios_por_liga : 10
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
      plano: :basic,
      ativa: true
    )
  end

  BAD_WORDS = [
    "viado", "fdp", "caralho", "porra", "merda", "puta", "puto", "cu", "cacete", "bosta",
    "chupa", "viadinho", "arrombado", "cuzao", "foder", "foda", "fodido", "fodida",
    "babaca", "otario", "otaria", "escroto", "escrota", "corno", "cornuda", "vaca",
    "paspalho", "imbecil", "idiota", "lixo", "verme", "maldito", "maldita", "desgraçado",
    "desgraçada", "pinto", "caralhao", "xereca", "xota", "buceta", "grelo", "caceta",
    "bostao", "merdao", "punheta", "siririca", "viadasso", "boiola", "bicha", "bichona",
    "sapatao", "traveco", "rabeta", "rabao", "bundao", "foda-se", "fodase", "fodete",
    "filhodaputa", "filha_da_puta", "filhodequenga", "cuzao", "cuzinho",
    "v1ad0", "p0rra", "c4r4lh0", "sh1t", "f0d4", "f_d_p", "fdps", "arrombad0",
    "fuck", "fucker", "fucking", "fuckface", "shit", "shitting", "shitter", "bitch",
    "bitches", "ass", "asshole", "assholes", "bastard", "dick", "dickhead", "cunt",
    "pussy", "twat", "wanker", "prick", "cock", "suck", "sucker", "motherfucker",
    "milf", "slut", "whore", "nigger", "faggot", "dyke", "retard", "crap",
    "macaco", "macaca", "tiziu", "crioulo", "crioula", "senzala", "nazista", "hitler",
    "pedofilo", "pedofila", "estuprador", "estupro", "mãe"
  ].freeze

  def name_must_be_appropriate
    return if name.blank?

    normalized_name = name.to_s.downcase.parameterize(separator: ' ')
    name_words = normalized_name.split
    no_spaces_name = normalized_name.gsub(/\s+/, '')

    BAD_WORDS.each do |bad_word|
      if name_words.include?(bad_word) || no_spaces_name.include?(bad_word)
        errors.add(:name, "contém termo impróprio")
        break
      end
    end
  end
end
