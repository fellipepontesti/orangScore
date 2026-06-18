class SyncPlayersDataJob < ApplicationJob
  queue_as :default

  def perform(year: '2026', user_id: nil, selecao_id: nil)
    selecao = Selecao.find_by(id: selecao_id) if selecao_id.present?
    result = Jogos::SyncSquads.new(selecao: selecao, year: year, import_squad: false).call

    if user_id.present?
      user = User.find_by(id: user_id)
      if user&.root?
        prefix = selecao ? "Sincronização de gols da seleção #{selecao.nome}" : "Sincronização de artilharia para o ano #{year}"
        
        if result[:success] && result[:warnings].blank?
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "#{prefix} concluída com sucesso!"
          )
        elsif result[:success] && result[:warnings].present?
          warning_text = result[:warnings].join("\n")
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "#{prefix} concluída com avisos:\n#{warning_text}"
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
