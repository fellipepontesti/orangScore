class SyncAllStatisticsJob < ApplicationJob
  queue_as :default

  def perform(year: '2026', user_id: nil)
    result = Jogos::SyncMatchStatistics.sync_all(year: year)

    if user_id.present?
      user = User.find_by(id: user_id)
      if user&.root?
        if result[:success]
          texto = "Sincronização de todas as estatísticas para o ano #{year} concluída com sucesso! #{result[:count]} jogo(s) atualizado(s)."
          if result[:warning].present?
            texto += "\n\nAvisos:\n#{result[:warning]}"
          end
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: texto
          )
        else
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "Sincronização de todas as estatísticas falhou: #{result[:error]}"
          )
        end
      end
    end
  end
end
