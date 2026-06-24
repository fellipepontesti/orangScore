require "rails_helper"

RSpec.describe "PalpitesTabs", type: :request do
  let(:admin) { users(:one) }
  let(:user) { users(:two) }

  before do
    @jogo_programado_sem_palpite = jogos(:one)
    @jogo_programado_sem_palpite.update!(status: :programado, definir: false)

    @jogo_com_palpite = jogos(:two)
    @jogo_com_palpite.update!(status: :programado, definir: false)

    @palpite = palpites(:two)
    @palpite.update!(user: user, jogo: @jogo_com_palpite, gols_casa: 1, gols_fora: 1)

    user.palpites.where(jogo: @jogo_programado_sem_palpite).destroy_all
  end

  it "index should segment tabs correctly for normal user" do
    sign_in user
    get palpites_path
    expect(response).to have_http_status(:success)
    
    # Valida que as abas existem na página
    # No RSpec requests, podemos usar capybara matches ou nokogiri, ou simplesmente analisar o HTML da response.body.
    # Vamos validar pela presença do ID na string
    expect(response.body).to include('id="tab_nao_palpitados"')
    expect(response.body).to include('id="tab_palpitados"')
    expect(response.body).to include('id="tab_finalizados"')
    
    expect(response.body).to include(@jogo_programado_sem_palpite.mandante.nome)
  end

  it "index should load admin view with filters if root user" do
    sign_in admin
    get palpites_path, params: { admin_view: 'true' }
    expect(response).to have_http_status(:success)
    
    expect(response.body).to include("name=\"user_id\"")
    expect(response.body).to include("name=\"status\"")
    expect(response.body).to include("name=\"pontos\"")
    expect(response.body).to include("name=\"order\"")
  end
end
