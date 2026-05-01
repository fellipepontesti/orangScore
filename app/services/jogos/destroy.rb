module Jogos
  class Destroy
    def initialize(jogo:)
      @jogo = jogo
    end

    def call
      @jogo.destroy!
    end
  end
end
