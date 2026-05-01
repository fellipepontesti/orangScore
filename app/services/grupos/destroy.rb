module Grupos
  class Destroy
    def initialize(grupo:)
      @grupo = grupo
    end

    def call
      @grupo.destroy!
    end
  end
end
