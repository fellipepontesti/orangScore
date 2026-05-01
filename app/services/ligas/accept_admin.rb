module Ligas
  class AcceptAdmin
    def initialize(liga:, current_user:)
      @liga = liga
      @current_user = current_user
    end

    def call
      liga_membro = @liga.liga_membros.find_by(user_id: @current_user.id)

      unless liga_membro
        raise Exceptions::ServiceError, "Vínculo não encontrado"
      end

      liga_membro.update!(role: :admin)

      @current_user.notificacoes
                   .where(liga: @liga, tipo: :admin_invite)
                   .update_all(status: Notificacao.statuses[:read])
                   
      liga_membro
    end
  end
end
