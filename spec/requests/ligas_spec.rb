require "rails_helper"

RSpec.describe "Ligas", type: :request do
  let(:admin) { users(:one) }
  let(:liga) { ligas(:one) }

  before do
    sign_in admin
    
    # Atualiza assinatura para premium para evitar limites de ligas
    if admin.assinatura
      admin.assinatura.update!(plano: :premium, ativa: true)
    else
      Assinatura.create!(usuario: admin, plano: :premium, ativa: true)
    end
    admin.reload

    # Garante que o admin seja o dono da liga de teste
    liga.update!(owner_id: admin.id)
    # Garante que o admin seja membro aceito da liga de teste
    liga.liga_membros.find_or_create_by!(user_id: admin.id) do |m|
      m.status = :accepted
      m.role = :owner
    end
  end

  it "should get index" do
    get ligas_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_liga_path
    expect(response).to have_http_status(:success)
  end

  it "should create liga" do
    expect {
      post ligas_path, params: { liga: { nome: "Nova Liga Unica", publica: true, entrada_livre: true, owner_id: admin.id } }
    }.to change(Liga, :count).by(1)

    expect(response).to redirect_to(liga_path(Liga.last))
  end

  it "should show liga" do
    get liga_path(liga)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_liga_path(liga)
    expect(response).to have_http_status(:success)
  end

  it "should update liga" do
    patch liga_path(liga), params: { liga: { nome: "Nome Editado", publica: liga.publica, entrada_livre: liga.entrada_livre } }
    expect(response).to redirect_to(liga_path(liga))
  end

  it "should destroy liga" do
    expect {
      delete liga_path(liga)
    }.to change(Liga, :count).by(-1)

    expect(response).to redirect_to(ligas_path)
  end
end
