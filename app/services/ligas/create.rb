module Ligas
  class Create
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      if @params[:nome].present? && @params[:nome].to_s.length > 30
        notificar_roots_nome_longo(@params[:nome])
      end

      liga = Liga.new(@params)

      if limite_de_ligas_atingido?
        liga.errors.add(
          :base,
          'Seu plano atual permite apenas 1 liga. Faça upgrade para criar mais ligas.'
        )

        return liga
      end

      liga.owner_id = @current_user.id
      liga.membros = 1

      if liga.save
        LigaMembro.create!(
          liga: liga,
          user_id: @current_user.id,
          role: :owner,
          status: :accepted
        )
      end
      
      liga
    end

    private

    def notificar_roots_nome_longo(nome_liga)
      User.where(tipo: :root).each do |root_user|
        Notificacao.create!(
          user: root_user,
          sender: @current_user,
          texto: "O usuário #{@current_user.name} (email: #{@current_user.email}) tentou criar a liga '#{nome_liga}' com #{nome_liga.length} caracteres, excedendo o limite de 30 caracteres.",
          tipo: :system,
          status: :unread
        )
      end
    end

    def limite_de_ligas_atingido?
      @current_user.ligas.count >= @current_user.limite_ligas
    end
  end
end
