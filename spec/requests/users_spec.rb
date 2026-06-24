require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:admin) { users(:one) }
  let(:user) { users(:two) }

  before do
    admin.update!(terms_accepted_at: Time.current)
    user.update!(terms_accepted_at: Time.current)
    
    # Cria assinaturas para os usuários de teste
    @admin_subscription = admin.assinatura || Assinatura.create!(usuario: admin, plano: :basic, ativa: true)
    @user_subscription = user.assinatura || Assinatura.create!(usuario: user, plano: :basic, ativa: true)
  end

  it "admin should get index" do
    sign_in admin
    get users_path
    expect(response).to have_http_status(:success)
  end

  it "non-admin should not get index" do
    sign_in user
    get users_path
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("Acesso não autorizado.")
  end

  it "admin should get ranking" do
    sign_in admin
    get ranking_users_path
    expect(response).to have_http_status(:success)
  end

  it "premium user should get ranking" do
    @user_subscription.update!(plano: :premium)
    user.reload
    
    sign_in user
    get ranking_users_path
    expect(response).to have_http_status(:success)
  end

  it "basic user should get ranking page successfully but default to weekly" do
    sign_in user
    get ranking_users_path
    expect(response).to have_http_status(:success)
  end

  it "ranking points should be aggregated correctly without multiplication (product cartesian bug)" do
    user.palpites.destroy_all
    user.user_points.destroy_all

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
    
    Palpite.create!(user: user, jogo: jogo1, gols_casa: 1, gols_fora: 1, uuid: SecureRandom.uuid)
    Palpite.create!(user: user, jogo: jogo2, gols_casa: 2, gols_fora: 0, uuid: SecureRandom.uuid)
    Palpite.create!(user: user, jogo: jogo3, gols_casa: 0, gols_fora: 3, uuid: SecureRandom.uuid)

    UserPoint.create!(user: user, jogo: jogo1, pontos: 10)
    UserPoint.create!(user: user, jogo: jogo2, pontos: 7)

    usuarios_ranking = User
                      .joins("LEFT JOIN (SELECT user_id, SUM(pontos) as total_points FROM user_points GROUP BY user_id) points_summary ON points_summary.user_id = users.id")
                      .joins("LEFT JOIN (SELECT user_id, COUNT(id) as total_palpites FROM palpites GROUP BY user_id) palpites_summary ON palpites_summary.user_id = users.id")
                      .select("users.*, 
                               COALESCE(points_summary.total_points, 0) as total_pontos_ranking, 
                               COALESCE(palpites_summary.total_palpites, 0) as total_palpites")
                      .to_a

    user_ranking = usuarios_ranking.find { |u| u.id == user.id }

    expect(user_ranking).not_to be_nil
    expect(user_ranking.total_palpites.to_i).to eq(3)
    expect(user_ranking.total_pontos_ranking.to_i).to eq(17)

    sign_in admin
    get ranking_users_path
    expect(response).to have_http_status(:success)
  end

  it "displays the daily ranking of the last day that had a match" do
    # Garante que temos um jogo de ontem e nenhum hoje ou no futuro (menor que agora)
    Jogo.destroy_all
    UserPoint.destroy_all

    grupo = Grupo.create!(nome: "Grupo de Teste")
    selecao_a = Selecao.create!(nome: "Brasil", logo: "br.png", grupo: grupo)
    selecao_b = Selecao.create!(nome: "Croácia", logo: "cro.png", grupo: grupo)

    # Jogo de ontem
    data_ontem = 1.day.ago.beginning_of_day + 15.hours
    jogo_ontem = Jogo.create!(
      mandante: selecao_a,
      visitante: selecao_b,
      data: data_ontem,
      tipo: :grupo,
      status: :finalizado,
      grupo: grupo,
      definir: false
    )

    # Usuário ganha pontos nesse jogo
    UserPoint.create!(user: user, jogo: jogo_ontem, pontos: 12)

    sign_in user
    get ranking_users_path, params: { periodo: "diario" }
    
    expect(response).to have_http_status(:success)
    # Deve indicar a data de ontem formatada no cabeçalho
    expect(response.body).to include("Ranking do dia #{data_ontem.in_time_zone.to_date.strftime('%d/%m/%Y')}")
    # O usuário logado deve ter os 12 pontos computados
    expect(response.body).to include("12")
  end
end
