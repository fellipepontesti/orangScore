require "rails_helper"

RSpec.describe Selecao, type: :model do
  it "deve recalcular estatisticas da selecao com base nos jogos" do
    grupo = Grupo.create!(nome: "Grupo de Teste")
    
    selecao_a = Selecao.create!(nome: "Selecao A", logo: "a.png", grupo: grupo)
    selecao_b = Selecao.create!(nome: "Selecao B", logo: "b.png", grupo: grupo)
    
    jogo = Jogo.create!(
      mandante: selecao_a,
      visitante: selecao_b,
      data: Time.current,
      tipo: :grupo,
      status: :programado,
      grupo: grupo,
      definir: false
    )
    
    # 1. Jogo Programado -> Sem estatísticas computadas
    expect(selecao_a.reload.gols).to eq(0)
    expect(selecao_a.gols_sofridos).to eq(0)
    expect(selecao_a.pontos).to eq(0)
    expect(selecao_a.qtd_jogos).to eq(0)

    # 2. Jogo em Andamento -> Gols e Saldo devem computar, mas sem pontos ou vitorias
    jogo.update!(status: :em_andamento, gols_mandante: 3, gols_visitante: 1)
    
    expect(selecao_a.reload.gols).to eq(3)
    expect(selecao_a.gols_sofridos).to eq(1)
    expect(selecao_a.pontos).to eq(0)
    expect(selecao_a.qtd_jogos).to eq(0)
    
    expect(selecao_b.reload.gols).to eq(1)
    expect(selecao_b.gols_sofridos).to eq(3)
    expect(selecao_b.pontos).to eq(0)
    expect(selecao_b.qtd_jogos).to eq(0)

    # 3. Jogo Finalizado -> Pontos, vitorias e jogos jogados computados
    jogo.update!(status: :finalizado)
    
    expect(selecao_a.reload.gols).to eq(3)
    expect(selecao_a.gols_sofridos).to eq(1)
    expect(selecao_a.pontos).to eq(3)
    expect(selecao_a.qtd_jogos).to eq(1)
    expect(selecao_a.vitorias).to eq(1)
    expect(selecao_a.empates).to eq(0)
    expect(selecao_a.derrotas).to eq(0)
    
    expect(selecao_b.reload.gols).to eq(1)
    expect(selecao_b.gols_sofridos).to eq(3)
    expect(selecao_b.pontos).to eq(0)
    expect(selecao_b.qtd_jogos).to eq(1)
    expect(selecao_b.vitorias).to eq(0)
    expect(selecao_b.empates).to eq(0)
    expect(selecao_b.derrotas).to eq(1)
  end
end
