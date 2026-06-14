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
        grupo = Grupo.find_by(uuid: params[:grupo])
        query = grupo ? query.where(grupo_id: grupo.id) : query.none
      end

      if params[:status].present?
        query = query.where(status: params[:status])
      end

      if params[:start_date].present?
        query = query.where('data >= ?', parsed_day(params[:start_date]).beginning_of_day)
      end

      if params[:end_date].present?
        query = query.where('data <= ?', parsed_day(params[:end_date]).end_of_day)
      end

      query
    end

    def parsed_day(value)
      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      Time.zone.today
    end
  end
end
