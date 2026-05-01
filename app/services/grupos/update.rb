module Grupos
  class Update
    def initialize(grupo:, params:)
      @grupo = grupo
      @params = params
    end

    def call
      @grupo.update(@params)
      @grupo
    end
  end
end
