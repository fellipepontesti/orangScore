class SyncSquadsOnlyJob < ApplicationJob
  queue_as :default

  def perform(year: '2026', user_id: nil)
    result = Jogos::SyncSquads.new(year: year, import_goals: false).call

    if user_id.present?
      user = User.find_by(id: user_id)
      if user&.root?
        if result[:success]
          texto = "Sincronização de elencos (sem gols) para o ano #{year} concluída com sucesso!"
          if result[:count].present?
            texto += "\n#{result[:count]} jogadores importados/atualizados."
          end
          if result[:teams_count].present?
            texto += "\n#{result[:teams_count]} seleções processadas."
          end
          if result[:warnings].present?
            texto += "\n\nAvisos:\n#{result[:warnings].join("\n")}"
          end
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: texto
          )
        else
          error_text = result[:error] || "Erro desconhecido"
          warning_text = result[:warnings].present? ? "\n\nAvisos parciais:\n#{result[:warnings].join("\n")}" : ""
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "Sincronização de elencos falhou:\n#{error_text}#{warning_text}"
          )
        end
      end
    end
  end
end
