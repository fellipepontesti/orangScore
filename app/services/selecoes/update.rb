module Selecoes
  class Update
    def initialize(selecao:, params:)
      @selecao = selecao
      @params = params
    end

    def call
      @selecao.update(@params)
      @selecao
    end
  end
end
