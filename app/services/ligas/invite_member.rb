module Ligas
  class InviteMember
    def initialize(liga:, current_user:, email:)
      @liga = liga
      @current_user = current_user
      @email = email
    end

    def call
      user_invited = User.find_by(email: email)

      # if LigaMembro.exists?(liga: @liga, user: user_invited, status: :invited)
      #   raise Exceptions::ServiceError, 'Esse usuário já possui um convite pendente para esta liga'
      # end

      raise Exceptions::ServiceError, 'Usuário com esse e-mail não encontrado' unless user_invited

      if liga.liga_membros.accepted.exists?(user: user_invited)
        raise Exceptions::ServiceError, 'Esse usuário já faz parte da liga'
      end

      if liga.liga_membros.invited.exists?(user: user_invited)
        raise Exceptions::ServiceError, 'Esse usuário já possui um convite pendente'
      end

      ActiveRecord::Base.transaction do
        LigaMembro.create!(
          liga: liga,
          user: user_invited,
          invited_by_id: current_user.id,
          status: :invited,
          role: :member
        )

        Notificacao.create!(
          sender_id: current_user.id,
          user_id: user_invited.id,
          texto: "Convite para participar da liga: #{liga.nome}",
          tipo: :invite,
          liga_id: liga.id,
          status: 0,
          answered: false
        )
      end

      LigaInviteMailer.with(
        user: user_invited,
        liga: liga,
        invited_by: current_user
      ).invite_member.deliver_later

      user_invited
    end

    private

    attr_reader :liga, :current_user, :email
  end
end