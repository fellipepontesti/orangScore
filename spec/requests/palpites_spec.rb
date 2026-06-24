require "rails_helper"

RSpec.describe "Palpites", type: :request do
  let(:user) { users(:two) }
  let(:palpite) { palpites(:two) }
  let(:jogo) { palpite.jogo }

  before do
    sign_in user
    jogo.update!(status: :programado)
  end

  it "should get index" do
    get palpites_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_palpite_path(jogo_id: jogo.uuid)
    expect(response).to have_http_status(:success)
  end

  it "should create palpite" do
    jogo_one = jogos(:one)
    jogo_one.update!(status: :programado)
    user.palpites.where(jogo: jogo_one).destroy_all

    expect {
      post palpites_path, params: { palpite: { gols_casa: 2, gols_fora: 1, jogo_id: jogo_one.uuid } }
    }.to change(Palpite, :count).by(1)

    expect(response).to redirect_to(jogos_path(tipo: jogo_one.tipo, grupo: jogo_one.grupo&.uuid))
  end

  it "should show palpite" do
    get palpite_path(palpite)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_palpite_path(palpite)
    expect(response).to have_http_status(:success)
  end

  it "should update palpite" do
    patch palpite_path(palpite), params: { palpite: { gols_casa: 3, gols_fora: 2 } }
    expect(response).to redirect_to(jogos_path(tipo: jogo.tipo, grupo: jogo.grupo&.uuid))
  end
end
