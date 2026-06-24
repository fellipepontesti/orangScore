require "rails_helper"

RSpec.describe "Notificacoes", type: :request do
  let(:admin) { users(:one) }
  let(:notificacao) { notificacoes(:one) }

  before do
    sign_in admin
  end

  it "should get index" do
    get notificacoes_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_notificacao_path
    expect(response).to have_http_status(:success)
  end

  it "should create notificacao for all users" do
    expect {
      post notificacoes_path, params: { notificacao: { texto: "Nova notificação", link: "http://example.com" } }
    }.to change(Notificacao, :count).by(User.count)

    expect(response).to redirect_to(notificacoes_path)
  end

  it "should show notificacao" do
    get notificacao_path(notificacao)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_notificacao_path(notificacao)
    expect(response).to have_http_status(:success)
  end

  it "should update notificacao" do
    patch notificacao_path(notificacao), params: { notificacao: { texto: "Texto atualizado", link: "http://example.com" } }
    expect(response).to redirect_to(notificacao_path(notificacao))
  end

  it "should destroy notificacao" do
    expect {
      delete notificacao_path(notificacao)
    }.to change(Notificacao, :count).by(-1)

    expect(response).to redirect_to(notificacoes_path)
  end
end
