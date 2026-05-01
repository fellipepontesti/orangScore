module Selecoes
  class Create
    def initialize(params:)
      @params = params
    end

    def call
      selecao = Selecao.new(@params)
      
      if Selecao.where(grupo_id: @params[:grupo_id]).count >= 4
        selecao.errors.add(:base, "Grupo cheio!")
        return selecao
      end

      selecao.save
      selecao
    end
  end
end
