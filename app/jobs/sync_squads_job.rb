class SyncSquadsJob < ApplicationJob
  queue_as :default

  def perform(selecao_id: nil, api_name: nil, year: '2026')
    if selecao_id.present?
      selecao = Selecao.find_by(id: selecao_id)
      return unless selecao

      Jogos::SyncSquads.new(selecao: selecao, api_name: api_name, year: year).call
    else
      Jogos::SyncSquads.new(year: year).call
    end
  end
end
