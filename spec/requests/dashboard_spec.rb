require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:admin) { users(:one) }
  let(:user) { users(:two) }

  before do
    # Criar um usuário semi_root para os testes com esconder_odds: false
    @semi = User.find_by(email: "semi@orang.com.br")
    unless @semi
      @semi = User.new(
        name: "Operador Semi",
        email: "semi@orang.com.br",
        selecao: selecoes(:one),
        tipo: :semi_root,
        confirmed_at: Time.current,
        terms_accepted_at: Time.current,
        esconder_odds: false
      )
      @semi.password = "Semi#123"
      @semi.password_confirmation = "Semi#123"
      @semi.terms_of_service = "1"
      @semi.save!
    end
    
    # Garantir que a assinatura exista
    Assinatura.find_or_create_by!(usuario: user) do |a|
      a.plano = :basic
      a.ativa = true
    end
  end

  it "should get index for normal user" do
    sign_in user
    get authenticated_root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Ranking Global")
  end

  it "should get index for semi_root user and render semi_root_index" do
    sign_in @semi
    get authenticated_root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Painel Operacional")
  end

  it "should get index for root user and render root_index" do
    sign_in admin
    get authenticated_root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Total de Usuários")
  end

  it "normal user should not access convites_pendentes" do
    sign_in user
    get dashboard_convites_pendentes_path
    expect(response).to redirect_to(authenticated_root_path)
    expect(flash[:alert]).to eq("Acesso não autorizado.")
  end

  it "root user should access convites_pendentes" do
    sign_in admin
    get dashboard_convites_pendentes_path
    expect(response).to have_http_status(:success)
  end
end
