require "rails_helper"

RSpec.describe Jogos::TeamMapping, type: :service do
  describe ".api_team_code" do
    it "retorna codigo FIFA para selecoes mapeadas" do
      expect(Jogos::TeamMapping.api_team_code("Brasil")).to eq("BRA")
      expect(Jogos::TeamMapping.api_team_code("Suiça")).to eq("SUI")
      expect(Jogos::TeamMapping.api_team_code("Suíça")).to eq("SUI")
      expect(Jogos::TeamMapping.api_team_code("Cróacia")).to eq("CRO")
      expect(Jogos::TeamMapping.api_team_code("Croácia")).to eq("CRO")
      expect(Jogos::TeamMapping.api_team_code("Coréia do Sul")).to eq("KOR")
      expect(Jogos::TeamMapping.api_team_code("Coreia do Sul")).to eq("KOR")
      expect(Jogos::TeamMapping.api_team_code("Jordânia")).to eq("JOR")
      expect(Jogos::TeamMapping.api_team_code("Jordania")).to eq("JOR")
    end

    it "retorna nil quando codigo FIFA nao esta mapeado" do
      expect(Jogos::TeamMapping.api_team_code("Selecao inexistente")).to be_nil
      expect(Jogos::TeamMapping.api_team_code(nil)).to be_nil
      expect(Jogos::TeamMapping.api_team_code(" ")).to be_nil
    end
  end
end
