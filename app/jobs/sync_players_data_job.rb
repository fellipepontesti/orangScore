class SyncPlayersDataJob < ApplicationJob
  queue_as :default

  def perform(year: '2026')
    Jogos::SyncSquads.new(year: year, import_squad: false).call
  end
end
