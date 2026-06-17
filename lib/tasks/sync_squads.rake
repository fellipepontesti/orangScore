namespace :sync do
  desc "Sincroniza os elencos e gols/assistencias dos jogadores da Copa de 2026 via API Zafronix"
  task squads: :environment do
    puts "Iniciando sincronização dos elencos da Copa de 2026..."
    result = Jogos::SyncSquads.new(year: '2026').call
    if result[:success]
      puts "Sincronização concluída com sucesso! Total de jogadores: #{result[:count]} em #{result[:teams_count]} seleções."
    else
      puts "Erro na sincronização: #{result[:error]}"
    end
  end
end
