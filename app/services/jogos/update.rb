module Jogos
  class Update
    def initialize(jogo:, params:)
      @jogo = jogo
      @params = params
    end

    def call
      if jogo.update(params)
        Jogos::StatusNotifier.new(jogo: jogo).call if jogo.saved_change_to_status?
        Jogos::CalculaPontuacao.new(jogo: jogo).call if jogo.finalizado? && (jogo.saved_change_to_status? || jogo.saved_change_to_gols_mandante? || jogo.saved_change_to_gols_visitante?)
      end
      jogo
    end

    private

    attr_reader :jogo, :params
  end
end