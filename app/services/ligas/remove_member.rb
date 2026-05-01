module Ligas
  class RemoveMember
    def initialize(liga:, current_user:, liga_membro_id:)
      @liga = liga
      @current_user = current_user
      @liga_membro_id = liga_membro_id
    end

    def call
      meu_vinculo = @liga.liga_membros.find_by(user_id: @current_user.id)

      unless meu_vinculo&.role.in?(%w[owner admin])
        raise Exceptions::ServiceError, "Você não tem permissão para remover membros."
      end

      liga_membro = @liga.liga_membros.find_by(id: @liga_membro_id)

      if liga_membro.nil?
        raise Exceptions::ServiceError, "Membro não encontrado."
      end

      if liga_membro.role == "owner"
        raise Exceptions::ServiceError, "O dono da liga não pode ser removido."
      end

      if meu_vinculo.role == "owner"
        liga_membro.destroy!
        return { status: :removed }
      end

      if meu_vinculo.role == "admin" && liga_membro.role == "member"
        liga_membro.update!(status: :pending_deletion)
        return { status: :pending }
      end

      raise Exceptions::ServiceError, "Ação não permitida."
    end
  end
end
