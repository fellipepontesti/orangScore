class SyncAllStatisticsJob < ApplicationJob
  queue_as :default

  def perform(year: '2026')
    Jogos::SyncMatchStatistics.sync_all(year: year)
  end
end
