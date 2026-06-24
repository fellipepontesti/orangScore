require "rails_helper"

RSpec.describe Jogos::SyncSquads, type: :service do
  describe "#consolidate_goals_from_matches" do
    let(:grupo) { Grupo.create!(nome: "Grupo A") }
    let!(:selecao_home) { Selecao.create!(nome: "Brasil", logo: "br.png", grupo: grupo) }
    let!(:selecao_away) { Selecao.create!(nome: "Croácia", logo: "cro.png", grupo: grupo) }
    
    let!(:jogador_local) do
      Jogador.create!(
        selecao: selecao_home,
        nome: "Neymar Jr",
        numero: 10,
        posicao: "FW",
        gols: 0
      )
    end

    let!(:jogo_local) do
      Jogo.create!(
        mandante: selecao_home,
        visitante: selecao_away,
        data: Time.current,
        tipo: :grupo,
        status: :finalizado,
        grupo: grupo,
        definir: false
      )
    end

    let(:matches_response) do
      {
        "data" => [
          {
            "status" => "finished",
            "homeTeam" => "Brasil",
            "awayTeam" => "Croácia",
            "goals" => [
              {
                "scorer" => "Neymar Jr",
                "minute" => 10,
                "team" => "home",
                "assist" => nil
              }
            ],
            "lineups" => {
              "home" => [
                { "player" => "Alisson", "number" => 1 },
                { "player" => "Thiago Silva", "number" => 3 }
              ],
              "away" => []
            }
          }
        ]
      }
    end

    before do
      # Mock da chamada HTTP para a API do Zafronix usando objeto real para passar no is_a?(Net::HTTPSuccess)
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(matches_response.to_json)
      allow(Net::HTTP).to receive(:start).and_return(response)
    end

    it "incrementa os gols do jogador encontrado no elenco local mesmo fora da escalacao (lineup)" do
      sync_service = Jogos::SyncSquads.new(import_squad: false, import_goals: true)
      
      expect {
        sync_service.call
      }.to change { jogador_local.reload.gols }.from(0).to(1)
    end
  end
end
