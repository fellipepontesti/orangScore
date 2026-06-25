class SeedConquistas < ActiveRecord::Migration[7.1]
  def up
    # 1. Pontuação
    Conquista.find_or_create_by!(slug: 'pontos_2') do |c|
      c.nome = 'Participação Garantida'
      c.descricao = 'Pontuou com palpite básico de participação (2 pontos).'
      c.icon = '🎯'
      c.cor = 'bg-slate-700/50 text-slate-300 border-slate-600/30'
    end

    Conquista.find_or_create_by!(slug: 'pontos_5') do |c|
      c.nome = 'Farol do Vencedor'
      c.descricao = 'Acertou o vencedor ou empate da partida (5 pontos).'
      c.icon = '🔍'
      c.cor = 'bg-blue-600/20 text-blue-400 border-blue-500/30'
    end

    Conquista.find_or_create_by!(slug: 'pontos_7') do |c|
      c.nome = 'Quase Perfeito'
      c.descricao = 'Acertou o vencedor/empate e os gols de uma das seleções (7 pontos).'
      c.icon = '📐'
      c.cor = 'bg-purple-600/20 text-purple-400 border-purple-500/30'
    end

    Conquista.find_or_create_by!(slug: 'pontos_10') do |c|
      c.nome = 'Profeta do Placar'
      c.descricao = 'Acertou em cheio o placar exato de um jogo (10 pontos).'
      c.icon = '🏆'
      c.cor = 'bg-warning/20 text-warning border-warning/30'
    end

    Conquista.find_or_create_by!(slug: 'pontos_25') do |c|
      c.nome = 'Coração de Ouro'
      c.descricao = 'Acertou a grande seleção campeã do torneio (25 pontos).'
      c.icon = '👑'
      c.cor = 'bg-amber-400/20 text-amber-300 border-amber-500/30'
    end

    # 2. Comportamento
    Conquista.find_or_create_by!(slug: 'primeiro_palpite') do |c|
      c.nome = 'Chute Inicial'
      c.descricao = 'Fez o seu primeiro palpite no bolão.'
      c.icon = '⚽'
      c.cor = 'bg-info/20 text-info border-info/30'
    end

    Conquista.find_or_create_by!(slug: 'mestre_do_empate') do |c|
      c.nome = 'Mestre do Empate'
      c.descricao = 'Acertou o placar exato de um empate.'
      c.icon = '🤝'
      c.cor = 'bg-success/20 text-success border-success/30'
    end

    Conquista.find_or_create_by!(slug: 'zebra') do |c|
      c.nome = 'Caçador de Zebras'
      c.descricao = 'Acertou a vitória de um azarão com menos de 25% de probabilidade.'
      c.icon = '🦓'
      c.cor = 'bg-secondary/20 text-secondary border-secondary/30'
    end

    Conquista.find_or_create_by!(slug: 'pe_quente') do |c|
      c.nome = 'Sequência Quente'
      c.descricao = 'Acertou o resultado (vencedor/empate) de 5 partidas consecutivas.'
      c.icon = '🔥'
      c.cor = 'bg-error/20 text-error border-error/30'
    end

    Conquista.find_or_create_by!(slug: 'tudo_ou_nada') do |c|
      c.nome = 'Profeta Completo'
      c.descricao = 'Registrou palpites para todos os jogos da Fase de Grupos.'
      c.icon = '⚡'
      c.cor = 'bg-primary/20 text-primary border-primary/30'
    end

    Conquista.find_or_create_by!(slug: 'criador_de_ligas') do |c|
      c.nome = 'Líder Nato'
      c.descricao = 'Criou uma liga personalizada para competir com amigos.'
      c.icon = '📣'
      c.cor = 'bg-teal-600/20 text-teal-400 border-teal-500/30'
    end

    Conquista.find_or_create_by!(slug: 'premium_user') do |c|
      c.nome = 'Apoiador Oficial'
      c.descricao = 'Tornou-se um assinante Premium do OrangScore.'
      c.icon = '⭐'
      c.cor = 'bg-pink-600/20 text-pink-400 border-pink-500/30'
    end

    # 3. Novas Conquistas Adicionais (Atualizadas)
    Conquista.find_or_create_by!(slug: 'palpites_50') do |c|
      c.nome = 'Veterano do Palpite'
      c.descricao = 'Fez pelo menos 50 palpites na plataforma.'
      c.icon = '📚'
      c.cor = 'bg-indigo-600/20 text-indigo-400 border-indigo-500/30'
    end

    Conquista.find_or_create_by!(slug: 'palpites_90') do |c|
      c.nome = 'Lenda dos Palpites'
      c.descricao = 'Fez pelo menos 90 palpites na plataforma.'
      c.icon = '🔮'
      c.cor = 'bg-pink-600/20 text-pink-400 border-pink-500/30'
    end

    Conquista.find_or_create_by!(slug: 'palpites_100') do |c|
      c.nome = 'Oráculo do Futebol'
      c.descricao = 'Fez pelo menos 100 palpites na plataforma.'
      c.icon = '🌌'
      c.cor = 'bg-violet-600/20 text-violet-400 border-violet-500/30'
    end

    Conquista.find_or_create_by!(slug: 'perfeito_10') do |c|
      c.nome = 'Goleada de Pontos'
      c.descricao = 'Acertou 10 placares exatos no torneio.'
      c.icon = '🌟'
      c.cor = 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30'
    end

    Conquista.find_or_create_by!(slug: 'amigos_5') do |c|
      c.nome = 'Mestre da Socialização'
      c.descricao = 'Colocou 4 amigos em uma liga, totalizando 5 participantes.'
      c.icon = '👥'
      c.cor = 'bg-cyan-600/20 text-cyan-400 border-cyan-500/30'
    end

    Conquista.find_or_create_by!(slug: 'referral_bonus') do |c|
      c.nome = 'Padrinho do Bolão'
      c.descricao = 'Conseguiu converter pelo menos um convite em membro ativo.'
      c.icon = '🤝'
      c.cor = 'bg-emerald-600/20 text-emerald-400 border-emerald-500/30'
    end

    Conquista.find_or_create_by!(slug: 'liga_cheia') do |c|
      c.nome = 'Liga Lotada'
      c.descricao = 'Participa ou criou uma liga com 10 ou mais membros ativos.'
      c.icon = '📢'
      c.cor = 'bg-teal-600/20 text-teal-400 border-teal-500/30'
    end

    Conquista.find_or_create_by!(slug: 'palpite_ultimo_segundo') do |c|
      c.nome = 'No Limite'
      c.descricao = 'Salvou um palpite nos últimos 5 minutos antes do início de uma partida.'
      c.icon = '⏱️'
      c.cor = 'bg-rose-600/20 text-rose-400 border-rose-500/30'
    end

    Conquista.find_or_create_by!(slug: 'rei_do_mata_mata') do |c|
      c.nome = 'Rei do Mata-Mata'
      c.descricao = 'Acertou o vencedor (pontuação >= 5) de pelo menos 5 jogos da fase eliminatória.'
      c.icon = '👑'
      c.cor = 'bg-fuchsia-600/20 text-fuchsia-400 border-fuchsia-500/30'
    end

    Conquista.find_or_create_by!(slug: 'azarado') do |c|
      c.nome = 'Quase Lá'
      c.descricao = 'Errou o placar exato por apenas 1 gol de diferença em um dos times (ganhou 7 pontos).'
      c.icon = '🩹'
      c.cor = 'bg-slate-600/20 text-slate-400 border-slate-500/30'
    end

    Conquista.find_or_create_by!(slug: 'palpitador_preciso') do |c|
      c.nome = 'Precisão Cirúrgica'
      c.descricao = 'Acertou pelo menos 3 placares exatos (10 pontos) no total.'
      c.icon = '🎯'
      c.cor = 'bg-amber-600/20 text-amber-400 border-amber-500/30'
    end

    # Remover obsoletas se existirem
    c_fiel = Conquista.find_by(slug: 'fiel_primeiro')
    if c_fiel
      UserConquista.where(conquista: c_fiel).destroy_all
      c_fiel.destroy
    end

    c_30 = Conquista.find_by(slug: 'palpites_30')
    if c_30
      UserConquista.where(conquista: c_30).destroy_all
      c_30.destroy
    end

    c_10 = Conquista.find_by(slug: 'palpites_10')
    if c_10
      UserConquista.where(conquista: c_10).destroy_all
      c_10.destroy
    end
  end

  def down
    # Nenhuma operação de deleção forçada no rollback
  end
end
