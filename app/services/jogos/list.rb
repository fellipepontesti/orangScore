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
        query = query.where(tipo: params[:tipo])
      end

      if params[:tipo] == 'grupo' && params[:grupo].present?
        grupo = Grupo.find_by(nome: params[:grupo])
        query = query.where(grupo_id: grupo.id) if grupo
      end

      if params[:status].present?
        query = query.where(status: params[:status])
      end

      if params[:start_date].present?
        query = query.where('data >= ?', params[:start_date])
      end

      if params[:end_date].present?
        query = query.where('data <= ?', params[:end_date])
      end

      query
    end
  end
end