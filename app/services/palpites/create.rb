module Palpites
  class Create
    attr_reader :jogo, :error_message

    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      @jogo = Jogo.find_by(uuid: params[:jogo_id])
      palpite = user.palpites.build(params.except(:jogo_id))

      unless jogo
        @error_message = "Jogo não informado."
        palpite.errors.add(:base, error_message)
        return palpite
      end

      if jogo.fechado_para_palpite?
        @error_message = "Não é possível palpitar em jogos em andamento ou finalizados."
        palpite.errors.add(:base, error_message)
        return palpite
      end

      palpite.jogo = jogo
      palpite.save
      palpite
    end

    private

    attr_reader :user, :params
  end
end
