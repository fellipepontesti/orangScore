module Ligas
  class Quit
    def initialize(liga:, current_user:)
      @liga = liga
      @current_user = current_user
    end

    def call
      membro = @liga.liga_membros.find_by(user_id: @current_user.id)

      raise StandardError, 'Você não faz parte desta liga.' if membro.nil?

      ActiveRecord::Base.transaction do
        membro.destroy!

        @liga.decrement!(:membros)

        return destroy_liga! if owner?(membro)

        true
      end
    end

    private

    def owner?(membro)
      membro.owner?
    end

    def destroy_liga!
      proximo_owner = @liga.liga_membros
                            .accepted
                            .order(:created_at)
                            .first

      if proximo_owner.present?
        proximo_owner.update!(role: :owner)

        novo_owner = User.find(proximo_owner.user_id)

        @liga.update!(owner_id: novo_owner.id)

        return true
      end

      @liga.destroy!

      true
    end
  end
end