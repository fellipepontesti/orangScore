require "rails_helper"

RSpec.describe Palpite, type: :model do
  let(:grupo) { Grupo.create!(nome: "Grupo de Teste") }
  let(:selecao_a) { Selecao.create!(nome: "Brasil", logo: "br.png", grupo: grupo) }
  let(:selecao_b) { Selecao.create!(nome: "Croácia", logo: "cro.png", grupo: grupo) }
  let(:user) { users(:two) }
  let(:jogo) do
    Jogo.create!(
      mandante: selecao_a,
      visitante: selecao_b,
      data: Time.current,
      tipo: :oitavas,
      definir: false
    )
  end

  before do
    user.update!(terms_accepted_at: Time.current)
  end

  it "automatically sets vencedor_penaltis_id when penalty scores are provided" do
    palpite = Palpite.new(
      user: user,
      jogo: jogo,
      gols_casa: 1,
      gols_fora: 1,
      gols_penaltis_casa: 5,
      gols_penaltis_fora: 3
    )

    expect(palpite.valid?).to be true
    expect(palpite.vencedor_penaltis_id).to eq(selecao_a.id)

    # Inverte os gols de pênaltis e valida se o vencedor muda
    palpite.gols_penaltis_casa = 3
    palpite.gols_penaltis_fora = 4
    palpite.valid?
    expect(palpite.vencedor_penaltis_id).to eq(selecao_b.id)
  end

  it "does not allow a tie in penalty shootout scores" do
    palpite = Palpite.new(
      user: user,
      jogo: jogo,
      gols_casa: 1,
      gols_fora: 1,
      gols_penaltis_casa: 4,
      gols_penaltis_fora: 4
    )

    expect(palpite.valid?).to be false
    expect(palpite.errors[:base]).to include("A disputa de pênaltis não pode terminar empatada.")
  end
end
