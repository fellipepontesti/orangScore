class Notificacao < ApplicationRecord
  belongs_to :user
  belongs_to :liga

  enum :status, { unread: 0, read: 1 }
  enum :tipo, { system: 0, invite: 1 }

  def partial_name
    "notificacoes/#{tipo}"
  end
end
