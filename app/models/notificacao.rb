class Notificacao < ApplicationRecord
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :user
  belongs_to :liga, optional: true

  enum :status, { unread: 0, read: 1 }
  enum :tipo, { system: 0, invite: 1, admin_invite: 2 }

  validates :user_id, uniqueness: {
    scope: [:liga_id, :tipo, :status],
    message: 'já possui um convite pendente para administrador'
  }, if: -> { tipo == 'admin_invite' && status == 'unread' }

  def partial_name
    "notificacoes/#{tipo}"
  end
end
