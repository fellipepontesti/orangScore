require "test_helper"

class LigaTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @jogo_antigo = jogos(:one)
    @jogo_novo = jogos(:two)
  end

  test "liga normal (pontuacao_zerada = false) computa todos os pontos do membro de forma retrospectiva" do
    # Criar uma liga normal
    liga = Liga.create!(
      owner: @user,
      nome: "Liga Normal",
      publica: true,
      entrada_livre: true,
      pontuacao_zerada: false,
      membros: 1
    )
    
    # Criar vinculo de membro
    membro = LigaMembro.create!(
      liga: liga,
      user: @user,
      role: :owner,
      status: :accepted,
      created_at: Time.current
    )

    # Criar ponto antigo (antes de entrar na liga)
    UserPoint.create!(
      user: @user,
      jogo: @jogo_antigo,
      pontos: 15,
      created_at: 1.day.ago
    )

    # Criar ponto novo (depois de entrar na liga)
    UserPoint.create!(
      user: @user,
      jogo: @jogo_novo,
      pontos: 10,
      created_at: 1.hour.from_now
    )

    # Pontos na liga devem ser a soma total de todos os pontos (15 + 10 + 1 da fixture)
    total_esperado = @user.user_points.sum(:pontos)
    assert_equal total_esperado, membro.reload.pontos_na_liga
    assert_equal total_esperado, liga.reload.total_pontos_liga

    # Validar que a query otimizada com_total_pontos também traz o total correto
    liga_com_pontos = Liga.com_total_pontos.find(liga.id)
    assert_equal total_esperado, liga_com_pontos.total_pontos_liga
  end

  test "liga com pontuacao_zerada = true computa apenas pontos criados apos o ingresso de cada membro" do
    # Criar uma liga zerada
    liga = Liga.create!(
      owner: @user,
      nome: "Liga Zerada",
      publica: true,
      entrada_livre: true,
      pontuacao_zerada: true,
      membros: 1
    )

    # Ponto antigo (criado antes de entrar na liga)
    ponto_antigo = UserPoint.create!(
      user: @user,
      jogo: @jogo_antigo,
      pontos: 15,
      created_at: 1.day.ago
    )

    # Criar vinculo de membro com data atual
    membro = LigaMembro.create!(
      liga: liga,
      user: @user,
      role: :owner,
      status: :accepted,
      created_at: Time.current
    )

    # Ponto novo (criado após entrar na liga)
    ponto_novo = UserPoint.create!(
      user: @user,
      jogo: @jogo_novo,
      pontos: 10,
      created_at: 1.hour.from_now
    )

    # Pontos na liga devem somar apenas o ponto novo (10)
    assert_equal 10, membro.reload.pontos_na_liga
    assert_equal 10, liga.reload.total_pontos_liga

    # Validar que a query otimizada com_total_pontos também computa apenas o ponto novo
    liga_com_pontos = Liga.com_total_pontos.find(liga.id)
    assert_equal 10, liga_com_pontos.total_pontos_liga
  end
end
