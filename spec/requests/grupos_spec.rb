require "rails_helper"

RSpec.describe "Grupos", type: :request do
  let(:admin) { users(:one) }
  let(:grupo) { grupos(:one) }

  before do
    sign_in admin
  end

  it "should get index" do
    get grupos_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_grupo_path
    expect(response).to have_http_status(:success)
  end

  it "should create grupo" do
    expect {
      post grupos_path, params: { grupo: { nome: grupo.nome, rodadas: grupo.rodadas } }
    }.to change(Grupo, :count).by(1)

    expect(response).to redirect_to(grupo_path(Grupo.last))
  end

  it "should show grupo" do
    get grupo_path(grupo)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_grupo_path(grupo)
    expect(response).to have_http_status(:success)
  end

  it "should update grupo" do
    patch grupo_path(grupo), params: { grupo: { nome: grupo.nome, rodadas: grupo.rodadas } }
    expect(response).to redirect_to(grupo_path(grupo))
  end

  it "should destroy grupo" do
    expect {
      delete grupo_path(grupo)
    }.to change(Grupo, :count).by(-1)

    expect(response).to redirect_to(grupos_path)
  end
end
