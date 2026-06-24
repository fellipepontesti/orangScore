require "rails_helper"

RSpec.describe Liga, type: :model do
  let(:user) { users(:one) }
  let(:jogo_antigo) { jogos(:one) }
  let(:jogo_novo) { jogos(:two) }

  it "liga normal (pontuacao_zerada = false) computa todos os pontos do membro de forma retrospectiva" do
    # Criar uma liga normal
    liga = Liga.create!(
      owner: user,
      nome: "Liga Normal",
      publica: true,
      entrada_livre: true,
      pontuacao_zerada: false,
      membros: 1
    )
    
    # Criar vinculo de membro
    membro = LigaMembro.create!(
      liga: liga,
      user: user,
      role: :owner,
      status: :accepted,
      created_at: Time.current
    )

    # Criar ponto antigo (antes de entrar na liga)
    UserPoint.create!(
      user: user,
      jogo: jogo_antigo,
      pontos: 15,
      created_at: 1.day.ago
    )

    # Criar ponto novo (depois de entrar na liga)
    UserPoint.create!(
      user: user,
      jogo: jogo_novo,
      pontos: 10,
      created_at: 1.hour.from_now
    )

    # Pontos na liga devem ser a soma total de todos os pontos (15 + 10 + 1 da fixture)
    total_esperado = user.user_points.sum(:pontos)
    expect(membro.reload.pontos_na_liga).to eq(total_esperado)
    expect(liga.reload.total_pontos_liga).to eq(total_esperado)

    # Validar que a query otimizada com_total_pontos também traz o total correto
    liga_com_pontos = Liga.com_total_pontos.find(liga.id)
    expect(liga_com_pontos.total_pontos_liga).to eq(total_esperado)
  end

  it "liga com pontuacao_zerada = true computa apenas pontos criados apos o ingresso de cada membro" do
    # Criar uma liga zerada
    liga = Liga.create!(
      owner: user,
      nome: "Liga Zerada",
      publica: true,
      entrada_livre: true,
      pontuacao_zerada: true,
      membros: 1
    )

    # Ponto antigo (criado antes de entrar na liga)
    ponto_antigo = UserPoint.create!(
      user: user,
      jogo: jogo_antigo,
      pontos: 15,
      created_at: 1.day.ago
    )

    # Criar vinculo de membro com data atual
    membro = LigaMembro.create!(
      liga: liga,
      user: user,
      role: :owner,
      status: :accepted,
      created_at: Time.current
    )

    # Ponto novo (criado após entrar na liga)
    ponto_novo = UserPoint.create!(
      user: user,
      jogo: jogo_novo,
      pontos: 10,
      created_at: 1.hour.from_now
    )

    # Pontos na liga devem somar apenas o ponto novo (10)
    expect(membro.reload.pontos_na_liga).to eq(10)
    expect(liga.reload.total_pontos_liga).to eq(10)

    # Validar que a query otimizada com_total_pontos também computa apenas o ponto novo
    liga_com_pontos = Liga.com_total_pontos.find(liga.id)
    expect(liga_com_pontos.total_pontos_liga).to eq(10)
  end

  it "Ligas::Create permite criacao de liga zerada para usuario comum" do
    test_user = users(:two)
    test_user.ligas.destroy_all
    
    if test_user.assinatura
      test_user.assinatura.update!(plano: :basic, ativa: true)
    else
      Assinatura.create!(usuario: test_user, plano: :basic, ativa: true)
    end
    test_user.reload
    
    service = Ligas::Create.new(
      current_user: test_user,
      params: { nome: "Liga Zerada Teste Comum", pontuacao_zerada: true, publica: true, entrada_livre: true }
    )
    liga = service.call
    
    expect(liga.persisted?).to be_truthy
    expect(liga.pontuacao_zerada?).to be_truthy
  end

  it "Ligas::Create permite criacao de liga zerada para usuario premium" do
    test_user = users(:two)
    test_user.ligas.destroy_all
    
    if test_user.assinatura
      test_user.assinatura.update!(plano: :premium, ativa: true)
    else
      Assinatura.create!(usuario: test_user, plano: :premium, ativa: true)
    end
    test_user.reload
    
    service = Ligas::Create.new(
      current_user: test_user,
      params: { nome: "Liga Zerada Teste Premium", pontuacao_zerada: true, publica: true, entrada_livre: true }
    )
    liga = service.call
    
    expect(liga.persisted?).to be_truthy
    expect(liga.pontuacao_zerada?).to be_truthy
  end
end
