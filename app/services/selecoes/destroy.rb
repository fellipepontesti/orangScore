module Selecoes
  class Destroy
    def initialize(selecao:)
      @selecao = selecao
    end

    def call
      @selecao.destroy!
    end
  end
end
