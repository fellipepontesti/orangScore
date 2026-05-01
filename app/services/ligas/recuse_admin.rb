module Ligas
  class RecuseAdmin
    def initialize(liga:, current_user:)
      @liga = liga
      @current_user = current_user
    end

    def call
      @current_user.notificacoes
                   .where(liga: @liga, tipo: :admin_invite)
                   .update_all(answered: true)
                   
      true
    end
  end
end
