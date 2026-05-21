module Notificacoes
  class ReferralCampaign
    TEXTO = 'Indique 5 amigos nos próximos dias e ganhe o plano Semi-Plus: sua liga passa a ter limite de 10 membros gratuitamente. (O seu amigo deverá criar a conta e entrar na sua liga para contar a indicação)'.freeze

    def self.call
      User.find_each do |user|
        next if Notificacao.exists?(user: user, tipo: :info, texto: TEXTO)

        Notificacao.create!(
          user: user,
          texto: TEXTO,
          tipo: :info,
          status: :unread
        )
      end
    end
  end
end
