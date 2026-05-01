module Ligas
  class Create
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      liga = Liga.new(@params)
      liga.owner_id = @current_user.id
      liga.membros = 1

      if liga.save
        LigaMembro.create!(
          liga: liga,
          user_id: @current_user.id,
          role: :owner,
          status: :accepted
        )
      end
      
      liga
    end
  end
end
