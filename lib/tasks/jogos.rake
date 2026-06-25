namespace :jogos do
  desc "Preenche e atualiza os confrontos do mata-mata baseado na API e classificação esportiva (não-destrutivo)"
  task preencher_mata_mata: :environment do
    puts "Iniciando preenchimento seguro do chaveamento..."
    
    # 1. Sincroniza chaves da API
    puts "Buscando confrontos oficiais da API..."
    api_res = Jogos::SyncKnockoutBracket.new.call
    if api_res[:success]
      puts "API atualizou #{api_res[:updated_count]} jogo(s) com sucesso!"
      if api_res[:warnings].present?
        puts "Avisos da API:\n#{api_res[:warnings].join("\n")}"
      end
    else
      puts "Aviso da API: #{api_res[:error]}"
    end

    # 2. Atualiza por classificação local (como fallback não-destrutivo)
    puts "Aplicando lógica esportiva local para jogos pendentes..."
    Jogos::BracketManager.atualizar
    puts "Chaveamento atualizado com sucesso!"
  end

  desc "Sincroniza os confrontos do mata-mata diretamente da API Zafronix"
  task sync_knockout_bracket: :environment do
    puts "Buscando chaves oficiais da API..."
    res = Jogos::SyncKnockoutBracket.new.call
    if res[:success]
      puts "Chaveamento sincronizado! #{res[:updated_count]} jogo(s) atualizado(s)."
      if res[:warnings].present?
        puts "Avisos da API:\n#{res[:warnings].join("\n")}"
      end
    else
      puts "Erro ao sincronizar via API: #{res[:error]}"
    end
  end
end
