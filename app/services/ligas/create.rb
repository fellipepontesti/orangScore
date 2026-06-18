module Ligas
  class Create
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      liga = Liga.new(@params)

      if limite_de_ligas_atingido?
        liga.errors.add(
          :base,
          'Seu plano atual permite apenas 1 liga. Faça upgrade para criar mais ligas.'
        )

        return liga
      end

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

    private

    def limite_de_ligas_atingido?
      @current_user.ligas.count >= @current_user.limite_ligas
    end
  end
end
