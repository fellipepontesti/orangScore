module Selecoes
  class List
    def initialize(params = {})
      @nome = params[:nome]
      @grupo_id = params[:grupo_id]
    end

    def call
      scope = Selecao.all.order(:nome)
      scope = scope.where('nome ILIKE ?', "%#{@nome}%") if @nome.present?
      scope = scope.where(grupo_id: @grupo_id) if @grupo_id.present?
      scope
    end
  end
end
