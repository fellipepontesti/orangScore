class SyncSquadsOnlyJob < ApplicationJob
  queue_as :default

  def perform(year: '2026')
    Jogos::SyncSquads.new(year: year, import_goals: false).call
  end
end
