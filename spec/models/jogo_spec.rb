require "rails_helper"

RSpec.describe Jogo, type: :model do
  let(:grupo) { Grupo.create!(nome: "Grupo de Teste") }
  let(:selecao_a) { Selecao.create!(nome: "Brasil", logo: "br.png", grupo: grupo) }
  let(:selecao_b) { Selecao.create!(nome: "Croácia", logo: "cro.png", grupo: grupo) }

  it "automatically sets vencedor_penaltis_id when penalty scores are provided" do
    jogo = Jogo.new(
      mandante: selecao_a,
      visitante: selecao_b,
      gols_mandante: 1,
      gols_visitante: 1,
      gols_penaltis_mandante: 5,
      gols_penaltis_visitante: 3,
      data: Time.current,
      tipo: :oitavas,
      definir: false
    )

    expect(jogo.valid?).to be true
    expect(jogo.vencedor_penaltis_id).to eq(selecao_a.id)

    # Inverte os gols de pênaltis e valida se o vencedor muda
    jogo.gols_penaltis_mandante = 3
    jogo.gols_penaltis_visitante = 4
    jogo.valid?
    expect(jogo.vencedor_penaltis_id).to eq(selecao_b.id)
  end

  it "does not allow a tie in penalty shootout scores" do
    jogo = Jogo.new(
      mandante: selecao_a,
      visitante: selecao_b,
      gols_mandante: 1,
      gols_visitante: 1,
      gols_penaltis_mandante: 4,
      gols_penaltis_visitante: 4,
      data: Time.current,
      tipo: :oitavas,
      definir: false
    )

    expect(jogo.valid?).to be false
    expect(jogo.errors[:base]).to include("A disputa de pênaltis não pode terminar empatada.")
  end
end
