module Jogos
  class List
    def initialize(params:)
      @params = params
    end

    def call
      query = ::Jogo.all.includes(:palpites)

      query = filtered_query(query)
      query.order(:data)
    end

    private

    attr_reader :params

    def filtered_query(query)
      if params[:tipo].present?
        query = query.where(tipo: Jogo.tipos[params[:tipo]])
      end

      if params[:tipo] == 'grupo' && params[:grupo].present?
        query = query.joins(:mandante)
                     .joins("INNER JOIN grupos ON grupos.id = selecoes.grupo_id")
                     .where(grupos: { nome: params[:grupo] })
      end

      query
    end
  end
end