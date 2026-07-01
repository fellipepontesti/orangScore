require "rails_helper"

RSpec.describe User, type: :model do
  let(:selecao) { Selecao.first || Selecao.create!(nome: "Brasil", logo: "BR.png") }

  describe "validação de espaços duplos no nome" do
    it "não permite nome com espaços em branco consecutivos" do
      user = User.new(
        name: "Fellipe  Pontes",
        email: "test@example.com",
        password: "Password123!",
        selecao_id: selecao.id,
        logo_selecao: "default.png",
        esconder_odds: false
      )
      expect(user.valid?).to be_falsey
      expect(user.errors[:name]).to include("não pode conter espaços em branco consecutivos")
    end

    it "permite nome com espaços simples" do
      user = User.new(
        name: "Fellipe Pontes",
        email: "test@example.com",
        password: "Password123!",
        selecao_id: selecao.id,
        logo_selecao: "default.png",
        esconder_odds: false
      )
      expect(user.valid?).to be_truthy
    end
  end
end
