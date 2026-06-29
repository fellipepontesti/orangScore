require "rails_helper"

RSpec.describe "Checkout", type: :request do
  let(:user) { users(:two) }

  before do
    user.update!(terms_accepted_at: Time.current)
    # Garante que a assinatura exista
    user.assinatura || Assinatura.create!(usuario: user, plano: :basic, ativa: true)
  end

  it "renders checkout pix page successfully" do
    cobranca = Cobranca.create!(
      user: user,
      plano: "premium",
      valor: 2990,
      status: :pendente,
      gateway: :mercado_pago,
      payment_method: :pix,
      pix_qr_code: "some_pix_code",
      pix_qr_code_base64: "some_base64_image_content"
    )

    sign_in user
    get checkout_pix_path(cobranca)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Pagamento via Pix")
    expect(response.body).not_to include("assinaturas_path")
  end
end
