module Ligas
  class RecuseInvite
    def initialize(liga_id, user_id)
      @liga_id = liga_id
      @user_id = user_id
    end

    def call
      @liga_membro = LigaMembro.find_by!(
        user_id: @user_id, 
        liga_id: @liga_id
      )

      @liga_membro.destroy!
    end
  end
end
