require "rails_helper"

RSpec.describe "Selecoes", type: :request do
  let(:admin) { users(:one) }
  let(:selecao) { selecoes(:one) }

  before do
    sign_in admin
  end

  it "should get index" do
    get selecoes_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_selecao_path
    expect(response).to have_http_status(:success)
  end

  it "should create selecao" do
    expect {
      post selecoes_path, params: { selecao: { derrotas: selecao.derrotas, empates: selecao.empates, qtd_jogos: selecao.qtd_jogos, logo: "escudo-novo.png", nome: "Nova Selecao Unica", pontos: selecao.pontos, vitorias: selecao.vitorias, grupo_id: selecao.grupo_id } }
    }.to change(Selecao, :count).by(1)

    expect(response).to redirect_to(selecao_path(Selecao.last))
  end

  it "should show selecao" do
    get selecao_path(selecao)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_selecao_path(selecao)
    expect(response).to have_http_status(:success)
  end

  it "should update selecao" do
    patch selecao_path(selecao), params: { selecao: { derrotas: selecao.derrotas, empates: selecao.empates, qtd_jogos: selecao.qtd_jogos, logo: selecao.logo, nome: selecao.nome, pontos: selecao.pontos, vitorias: selecao.vitorias, grupo_id: selecao.grupo_id } }
    expect(response).to redirect_to(selecao_path(selecao))
  end

  it "should destroy selecao" do
    expect {
      delete selecao_path(selecao)
    }.to change(Selecao, :count).by(-1)

    expect(response).to redirect_to(selecoes_path)
  end
end
