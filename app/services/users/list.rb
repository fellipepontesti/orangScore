module Users
  class List
    ORDER_OPTIONS = {
      "created_at" => "Data de criação",
      "sign_in_count" => "Quantidade de logins",
      "ranking" => "Ranking"
    }.freeze

    DIRECTION_OPTIONS = {
      "desc" => "Maior/mais recente primeiro",
      "asc" => "Menor/mais antigo primeiro"
    }.freeze

    def initialize(params = {})
      @nome     = params[:nome]
      @email    = params[:email]
      @selecao  = params[:selecao]
      @order    = ORDER_OPTIONS.key?(params[:order].to_s) ? params[:order].to_s : "created_at"
      @direction = DIRECTION_OPTIONS.key?(params[:direction].to_s) ? params[:direction].to_s : "desc"
    end

    def call
      # 1. Começamos com um objeto ActiveRecord::Relation (não use .to_a aqui!)
      usuarios = User.all
        .joins("LEFT JOIN user_points ON user_points.user_id = users.id")
        .joins("LEFT JOIN palpites ON palpites.user_id = users.id")
        .group("users.id")
        .select("users.*, 
                  COALESCE(SUM(user_points.pontos), 0) as total_pontos_ranking, 
                  COUNT(DISTINCT palpites.id) as total_palpites")

      usuarios = filtrar_nome(usuarios)
      usuarios = filtrar_email(usuarios)
      usuarios = filtrar_selecao(usuarios)

      ordenar(usuarios)
    end

    private

    attr_reader :order, :direction

    def filtrar_nome(scope)
      return scope unless @nome.present?
      scope.where("users.name ILIKE ?", "%#{@nome}%")
    end

    def filtrar_email(scope)
      return scope unless @email.present?
      scope.where("users.email ILIKE ?", "%#{@email}%")
    end

    def filtrar_selecao(scope)
      return scope unless @selecao.present?
      scope.where(selecao_id: @selecao) 
    end

    def ordenar(scope)
      case order
      when "sign_in_count"
        scope.order(Arel.sql("users.sign_in_count #{direction.upcase}, users.created_at DESC"))
      when "ranking"
        scope.order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
      else
        scope.order(Arel.sql("users.created_at #{direction.upcase}"))
      end
    end
  end
end
