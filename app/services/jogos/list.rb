module Jogos
  class List
    def initialize(params:)
      @params = params
    end

    def call
      query = ::Jogo.all.includes(:palpites, :user_points)

      # Se estivermos listando uma fase específica do mata-mata, permitimos a exibição
      # de jogos com confrontos ainda pendentes/parciais (definir: true ou times_a_definir).
      # Caso contrário (listagem geral ou grupos), mostramos apenas jogos já definidos.
      if params[:tipo].blank? || params[:tipo] == 'grupo'
        query = query.where(definir: false).where.not(status: :times_a_definir)
      end

      query = filtered_query(query)
      
      if params[:tipo] == 'grupo' && params[:grupo].present?
        query.order(Arel.sql("CASE WHEN status = #{::Jogo.statuses[:finalizado]} THEN 1 ELSE 0 END"), :data)
      else
        ordem_sql = "CASE 
          WHEN status IN (#{::Jogo.statuses[:em_andamento]}, #{::Jogo.statuses[:suspenso]}) THEN 0
          WHEN status IN (0, 3) THEN 1
          ELSE 2
        END"
        query.order(Arel.sql(ordem_sql), :data)
      end
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
