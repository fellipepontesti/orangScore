class SyncSquadsJob < ApplicationJob
  queue_as :default

  def perform(selecao_id: nil, api_name: nil, year: '2026', user_id: nil)
    result = if selecao_id.present?
      selecao = Selecao.find_by(id: selecao_id)
      if selecao
        Jogos::SyncSquads.new(selecao: selecao, api_name: api_name, year: year).call
      else
        { success: false, error: "Seleção com ID #{selecao_id} não encontrada localmente." }
      end
    else
      Jogos::SyncSquads.new(year: year).call
    end

    if user_id.present?
      user = User.find_by(id: user_id)
      if user&.root?
        prefix = selecao_id.present? ? "Sincronização do elenco da seleção (API: #{api_name})" : "Sincronização de todos os elencos e gols"
        
        if result[:success]
          texto = "#{prefix} para o ano #{year} concluída com sucesso!"
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
            texto: "#{prefix} falhou:\n#{error_text}#{warning_text}"
          )
        end
      end
    end
  end
end
