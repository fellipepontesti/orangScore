module Ligas
  class RecuseInvite
    def initialize(liga_id, user_id)
      @liga_id = liga_id
      @user_id = user_id
    end

    def call
      ActiveRecord::Base.transaction do
        liga_membro = LigaMembro.find_by!(
          user_id: @user_id,
          liga_id: @liga_id,
          status: :invited
        )

        liga_membro.destroy!

        Notificacao
          .where(user_id: @user_id, liga_id: @liga_id, tipo: :invite, status: :unread)
          .update_all(status: Notificacao.statuses[:read])
      end
    end
  end
end