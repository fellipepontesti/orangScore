module Jogos
  class Update
    def initialize(jogo:, params:)
      @jogo = jogo
      @params = params
    end

    def call
      jogo.update(params)
      jogo
    end

    private

    attr_reader :jogo, :params
  end
end