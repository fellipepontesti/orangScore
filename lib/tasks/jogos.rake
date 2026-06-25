namespace :jogos do
  desc "Preenche e atualiza os confrontos do mata-mata baseado nas classificações e resultados atuais"
  task preencher_mata_mata: :environment do
    puts "Iniciando preenchimento automático do chaveamento..."
    Jogos::BracketManager.atualizar
    puts "Chaveamento atualizado com sucesso!"
  end
end
