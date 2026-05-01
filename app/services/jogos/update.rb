module Jogos
  class Update
    def initialize(jogo:, params:)
      @jogo = jogo
      @params = params
    end

    def call
      if jogo.update(params)
        if jogo.saved_change_to_status? && jogo.finalizado?
          Jogos::CalculaPontuacao.new(jogo: jogo).call
        end
      end
      jogo
    end

    private

    attr_reader :jogo, :params
  end
end