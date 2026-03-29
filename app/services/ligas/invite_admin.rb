module Ligas
  class InviteAdmin
    def initialize(liga:, current_user:, liga_membro_id:)
      @liga = liga
      @current_user = current_user
      @liga_membro_id = liga_membro_id
    end

    def call
      meu_vinculo = liga.liga_membros.find_by(user_id: current_user.id)

      unless meu_vinculo&.owner?
        raise Exceptions::ServiceError, 'Você não tem permissão para promover membros.'
      end

      liga_membro = liga.liga_membros.find_by(id: liga_membro_id)

      raise Exceptions::ServiceError, 'Membro da liga não encontrado.' unless liga_membro
      raise Exceptions::ServiceError, 'Esse usuário já é owner da liga.' if liga_membro.owner?
      raise Exceptions::ServiceError, 'Esse usuário já é administrador da liga.' if liga_membro.admin?

      if Notificacao.exists?(
        user_id: liga_membro.user_id,
        liga_id: liga.id,
        tipo: :admin_invite,
        status: :unread
      )
        raise Exceptions::ServiceError, 'Esse usuário já possui um convite pendente para administrador.'
      end

      Notificacao.create!(
        sender_id: current_user.id,
        user_id: liga_membro.user_id,
        texto: "#{current_user.name} convidou você para se tornar administrador da liga #{liga.nome}.",
        tipo: :admin_invite,
        status: :unread,
        liga_id: liga.id,
        answered: false
      )

      liga_membro
    end

    private

    attr_reader :liga, :current_user, :liga_membro_id
  end
end