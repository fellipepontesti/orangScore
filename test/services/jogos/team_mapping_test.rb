require "test_helper"

module Jogos
  class TeamMappingTest < ActiveSupport::TestCase
    test "retorna codigo FIFA para selecoes mapeadas" do
      assert_equal "BRA", TeamMapping.api_team_code("Brasil")
      assert_equal "SUI", TeamMapping.api_team_code("Suiça")
      assert_equal "SUI", TeamMapping.api_team_code("Suíça")
      assert_equal "CRO", TeamMapping.api_team_code("Cróacia")
      assert_equal "CRO", TeamMapping.api_team_code("Croácia")
      assert_equal "KOR", TeamMapping.api_team_code("Coréia do Sul")
      assert_equal "KOR", TeamMapping.api_team_code("Coreia do Sul")
      assert_equal "JOR", TeamMapping.api_team_code("Jordânia")
      assert_equal "JOR", TeamMapping.api_team_code("Jordania")
    end

    test "retorna nil quando codigo FIFA nao esta mapeado" do
      assert_nil TeamMapping.api_team_code("Selecao inexistente")
      assert_nil TeamMapping.api_team_code(nil)
      assert_nil TeamMapping.api_team_code(" ")
    end
  end
end
