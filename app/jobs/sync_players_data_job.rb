class SyncPlayersDataJob < ApplicationJob
  queue_as :default

  def perform(year: '2026', user_id: nil)
    result = Jogos::SyncSquads.new(year: year, import_squad: false).call

    if user_id.present?
      user = User.find_by(id: user_id)
      if user&.root?
        if result[:success] && result[:warnings].blank?
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "Sincronização de artilharia para o ano #{year} concluída com sucesso!"
          )
        elsif result[:success] && result[:warnings].present?
          warning_text = result[:warnings].join("\n")
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "Sincronização de artilharia concluída com avisos:\n#{warning_text}"
          )
        else
          error_text = result[:error] || "Erro desconhecido"
          warning_text = result[:warnings].present? ? "\n\nAvisos parciais:\n#{result[:warnings].join("\n")}" : ""
          Notificacao.create!(
            user: user,
            tipo: :info,
            status: :unread,
            texto: "Sincronização de artilharia falhou:\n#{error_text}#{warning_text}"
          )
        end
      end
    end
  end
end
