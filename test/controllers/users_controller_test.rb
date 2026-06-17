require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(terms_accepted_at: Time.current)
    @user = users(:two)
    @user.update!(terms_accepted_at: Time.current)
    
    # Cria assinaturas para os usuários de teste
    Assinatura.create!(usuario: @admin, plano: :basic, ativa: true) unless @admin.assinatura
    @user_subscription = Assinatura.create!(usuario: @user, plano: :basic, ativa: true) unless @user.assinatura
  end

  test "admin should get index" do
    sign_in @admin
    get users_path
    assert_response :success
  end

  test "non-admin should not get index" do
    sign_in @user
    get users_path
    assert_redirected_to root_path
    assert_equal "Acesso não autorizado.", flash[:alert]
  end

  test "admin should get ranking" do
    sign_in @admin
    get ranking_users_path
    assert_response :success
  end

  test "premium user should get ranking" do
    # Muda a assinatura do usuário normal para premium
    @user_subscription.update!(plano: :premium)
    @user.reload
    
    sign_in @user
    get ranking_users_path
    assert_response :success
  end

  test "basic user should not get ranking and be redirected to plans" do
    sign_in @user
    get ranking_users_path
    assert_redirected_to planos_path
    assert_equal "O Ranking Global é uma funcionalidade exclusiva para assinantes Premium. Faça seu upgrade e confira sua posição!", flash[:alert]
  end

  test "ranking points should be aggregated correctly without multiplication (product cartesian bug)" do
    # Garante que limpamos dados anteriores de palpites e pontos do usuário
    @user.palpites.destroy_all
    @user.user_points.destroy_all

    # Cria 3 palpites em jogos diferentes
    jogo1 = jogos(:one)
    jogo2 = jogos(:two)
    jogo3 = Jogo.create!(
      mandante: jogo1.mandante,
      visitante: jogo1.visitante,
      gols_mandante: 2,
      gols_visitante: 1,
      data: Time.current,
      tipo: :grupo,
      grupo: jogo1.grupo,
      uuid: SecureRandom.uuid,
      definir: false
    )
    
    Palpite.create!(user: @user, jogo: jogo1, gols_casa: 1, gols_fora: 1, uuid: SecureRandom.uuid)
    Palpite.create!(user: @user, jogo: jogo2, gols_casa: 2, gols_fora: 0, uuid: SecureRandom.uuid)
    Palpite.create!(user: @user, jogo: jogo3, gols_casa: 0, gols_fora: 3, uuid: SecureRandom.uuid)

    # Cria 2 registros de pontos (user_points)
    # Total de pontos = 10 + 7 = 17
    UserPoint.create!(user: @user, jogo: jogo1, pontos: 10)
    UserPoint.create!(user: @user, jogo: jogo2, pontos: 7)

    # Executa a mesma query do controller para validar a lógica de banco de dados
    usuarios_ranking = User
                      .joins("LEFT JOIN (SELECT user_id, SUM(pontos) as total_points FROM user_points GROUP BY user_id) points_summary ON points_summary.user_id = users.id")
                      .joins("LEFT JOIN (SELECT user_id, COUNT(id) as total_palpites FROM palpites GROUP BY user_id) palpites_summary ON palpites_summary.user_id = users.id")
                      .select("users.*, 
                               COALESCE(points_summary.total_points, 0) as total_pontos_ranking, 
                               COALESCE(palpites_summary.total_palpites, 0) as total_palpites")
                      .to_a

    user_ranking = usuarios_ranking.find { |u| u.id == @user.id }

    assert_not_nil user_ranking
    assert_equal 3, user_ranking.total_palpites.to_i, "A contagem de palpites deve ser exatamente 3"
    assert_equal 17, user_ranking.total_pontos_ranking.to_i, "A pontuação acumulada deve ser exatamente 17 (e não multiplicada)"

    # Autentica como admin (para ter permissão de acesso) e garante que o controller renderiza com sucesso
    sign_in @admin
    get ranking_users_path
    assert_response :success
  end
end
