module Selecoes
  class List
    def initialize(params = {})
      @nome = params[:nome]
      @grupo_id = params[:grupo_id]
    end

    def call
      scope = Selecao.all
        .left_joins(:users)
        .group("selecoes.id")
        .select("selecoes.*, COUNT(users.id) as qtd_torcedores")
        .order(:nome)

      scope = scope.where('selecoes.nome ILIKE ?', "%#{@nome}%") if @nome.present?
      scope = scope.where(grupo_id: @grupo_id) if @grupo_id.present?
      
      scope
    end
  end
end