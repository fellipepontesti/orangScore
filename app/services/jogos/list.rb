module Jogos
  class List
    def initialize(params:)
      @params = params
    end

    def call
      query = ::Jogo.all

      query = filtered_query(query)
      query.order(:data)
    end

    private

    attr_reader :params

    def filtered_query(query)
      if @params[:tipo].present? 
        query.where(tipo: Jogo.tipos[params[:tipo]])
      end
    end
  end
end