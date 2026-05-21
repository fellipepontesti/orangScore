namespace :notificacoes do
  desc 'Cria a notificação da campanha de indicação para todos os usuários'
  task referral_campaign: :environment do
    Notificacoes::ReferralCampaign.call
  end
end
