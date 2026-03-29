module Jogos
  class Create
    def initialize(params:)
      @params = params
    end

    def call
      jogo = Jogo.new(@params)
      jogo.save
      jogo
    end

    private

    attr_reader :params
  end
end