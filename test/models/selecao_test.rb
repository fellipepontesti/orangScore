require "test_helper"

class SelecaoTest < ActiveSupport::TestCase
  test "deve recalcular estatisticas da selecao com base nos jogos" do
    grupo = Grupo.create!(nome: "Grupo de Teste")
    
    selecao_a = Selecao.create!(nome: "Selecao A", logo: "a.png", grupo: grupo)
    selecao_b = Selecao.create!(nome: "Selecao B", logo: "b.png", grupo: grupo)
    
    jogo = Jogo.create!(
      mandante: selecao_a,
      visitante: selecao_b,
      data: Time.current,
      tipo: :grupo,
      status: :programado,
      grupo: grupo
    )
    
    # 1. Jogo Programado -> Sem estatísticas computadas
    assert_equal 0, selecao_a.reload.gols
    assert_equal 0, selecao_a.gols_sofridos
    assert_equal 0, selecao_a.pontos
    assert_equal 0, selecao_a.qtd_jogos

    # 2. Jogo em Andamento -> Gols e Saldo devem computar, mas sem pontos ou vitorias
    jogo.update!(status: :em_andamento, gols_mandante: 3, gols_visitante: 1)
    
    assert_equal 3, selecao_a.reload.gols
    assert_equal 1, selecao_a.gols_sofridos
    assert_equal 0, selecao_a.pontos
    assert_equal 0, selecao_a.qtd_jogos
    
    assert_equal 1, selecao_b.reload.gols
    assert_equal 3, selecao_b.gols_sofridos
    assert_equal 0, selecao_b.pontos
    assert_equal 0, selecao_b.qtd_jogos

    # 3. Jogo Finalizado -> Pontos, vitorias e jogos jogados computados
    jogo.update!(status: :finalizado)
    
    assert_equal 3, selecao_a.reload.gols
    assert_equal 1, selecao_a.gols_sofridos
    assert_equal 3, selecao_a.pontos
    assert_equal 1, selecao_a.qtd_jogos
    assert_equal 1, selecao_a.vitorias
    assert_equal 0, selecao_a.empates
    assert_equal 0, selecao_a.derrotas
    
    assert_equal 1, selecao_b.reload.gols
    assert_equal 3, selecao_b.gols_sofridos
    assert_equal 0, selecao_b.pontos
    assert_equal 1, selecao_b.qtd_jogos
    assert_equal 0, selecao_b.vitorias
    assert_equal 0, selecao_b.empates
    assert_equal 1, selecao_b.derrotas
  end
end
