module Users
  class RankingHistoryService
    def initialize(user:, limit: 10)
      @user = user
      @limit = limit
    end

    def call
      # Obter os jogos mais recentes finalizados nos quais o usuário palpitou
      jogos = Jogo.finalizado
                  .joins(:palpites)
                  .where(palpites: { user_id: @user.id })
                  .order(data: :asc)
                  .last(@limit)

      return [] if jogos.empty?

      # Mapear todos os usuários do sistema
      users_data = User.pluck(:id, :created_at).to_h
      user_ids = users_data.keys
      return [] unless user_ids.include?(@user.id)

      # Limitar a busca de pontos e palpites até a data do último jogo analisado
      max_data = jogos.last.data
      all_user_points = UserPoint.joins(:jogo)
                                 .includes(:jogo)
                                 .where("jogos.data <= ?", max_data)
                                 .to_a

      all_palpites = Palpite.joins(:jogo)
                            .includes(:jogo)
                            .where("jogos.data <= ?", max_data)
                            .to_a

      history = []

      jogos.each do |jogo|
        # Calcular os pontos acumulados de cada usuário até o momento do jogo atual
        points_up_to_game = Hash.new(0)
        all_user_points.each do |up|
          if up.jogo.data <= jogo.data
            points_up_to_game[up.user_id] += up.pontos
          end
        end

        # Calcular o total de palpites de cada usuário até o momento do jogo atual
        palpites_up_to_game = Hash.new(0)
        all_palpites.each do |p|
          if p.jogo.data <= jogo.data
            palpites_up_to_game[p.user_id] += 1
          end
        end

        # Ordenar os competidores com as regras oficiais de desempate
        sorted_users = user_ids.sort_by do |u_id|
          [
            -points_up_to_game[u_id],
            -palpites_up_to_game[u_id],
            users_data[u_id] || Time.current
          ]
        end

        rank = sorted_users.index(@user.id)
        rank = rank ? rank + 1 : sorted_users.size + 1

        history << {
          data: "#{jogo.mandante&.nome || 'Mandante'} x #{jogo.visitante&.nome || 'Visitante'}",
          pontos: points_up_to_game[@user.id],
          posicao: rank
        }
      end

      history
    end
  end
end
