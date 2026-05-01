module Grupos
  class Create
    def initialize(params:)
      @params = params
    end

    def call
      grupo = Grupo.new(@params)
      grupo.save
      grupo
    end
  end
end
