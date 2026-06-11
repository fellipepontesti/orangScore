module Jogos
  class Start
    def initialize(jogo:)
      @jogo = jogo
    end

    def call
      if @jogo.em_andamento? || @jogo.finalizado?
        raise Exceptions::ServiceError, "O jogo já foi iniciado ou finalizado."
      end

      @jogo.update!(status: :em_andamento)
      Jogos::StatusNotifier.new(jogo: @jogo).call
      @jogo
    end
  end
end
