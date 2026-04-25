module Users
  class List
    def initialize(params = {})
      @nome     = params[:nome]
      @email    = params[:email]
      @selecao  = params[:selecao]
    end

    def call
      usuarios = User.all

      usuarios = filtrar_nome(usuarios)
      usuarios = filtrar_email(usuarios)
      usuarios = filtrar_selecao(usuarios)

      usuarios.order(pontos: :desc)
    end

    private

    def filtrar_nome(scope)
      return scope unless @nome.present?

      scope.where("name ILIKE ?", "%#{@nome}%")
    end

    def filtrar_email(scope)
      return scope unless @email.present?

      scope.where("email ILIKE ?", "%#{@email}%")
    end

    def filtrar_selecao(scope)
      return scope unless @selecao.present?

      scope.where(logo_selecao: @selecao)
    end
  end
end