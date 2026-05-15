module Users
  class List
    def initialize(params = {})
      @nome     = params[:nome]
      @email    = params[:email]
      @selecao  = params[:selecao]
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

      usuarios.order("total_pontos_ranking DESC, total_palpites DESC, users.created_at ASC")
    end

    private

    def filtrar_nome(scope)
      return scope unless @nome.present?
      scope.where("users.name ILIKE ?", "%#{@nome}%") # Adicionado 'users.' para evitar ambiguidade
    end

    def filtrar_email(scope)
      return scope unless @email.present?
      scope.where("users.email ILIKE ?", "%#{@email}%")
    end

    def filtrar_selecao(scope)
      return scope unless @selecao.present?
      scope.where(selecao_id: @selecao) 
    end
  end
end