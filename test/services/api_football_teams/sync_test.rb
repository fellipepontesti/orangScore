require "test_helper"

module ApiFootballTeams
  class SyncTest < ActiveSupport::TestCase
    setup do
      ApiFootballTeam.delete_all
      @grupo = Grupo.create!(nome: "Grupo Teste", rodadas: 0)
    end

    test "sincroniza selecao pelo codigo FIFA" do
      selecao = create_selecao!("Brasil")
      requested_endpoints = []

      ApiFootballClient.stub(:request, ->(endpoint) {
        requested_endpoints << endpoint
        {
          "response" => [
            {
              "team" => {
                "id" => 6,
                "name" => "Brazil",
                "country" => "Brazil",
                "code" => "BRA",
                "logo" => "https://example.com/brazil.png",
                "national" => true
              }
            }
          ]
        }
      }) do
        result = Sync.new.sync_team(selecao.nome)

        assert result[:success]
        assert_equal ["/teams?code=BRA"], requested_endpoints
        assert_equal "BRA", result[:api_team].code
        assert_equal selecao, result[:api_team].selecao
      end
    end

    test "sincroniza Jordania com resposta real da API Football" do
      selecao = create_selecao!("Jordânia")
      requested_endpoints = []

      ApiFootballClient.stub(:request, ->(endpoint) {
        requested_endpoints << endpoint
        {
          "get" => "teams",
          "parameters" => { "code" => "JOR" },
          "errors" => [],
          "results" => 1,
          "paging" => { "current" => 1, "total" => 1 },
          "response" => [
            {
              "team" => {
                "id" => 1548,
                "name" => "Jordan",
                "code" => "JOR",
                "country" => "Jordan",
                "founded" => 1949,
                "national" => true,
                "logo" => "https://media.api-sports.io/football/teams/1548.png"
              },
              "venue" => {
                "id" => 988,
                "name" => "Amman International Stadium"
              }
            }
          ]
        }
      }) do
        result = Sync.new.sync_team(selecao.nome)

        assert result[:success], result[:error]
        assert_equal ["/teams?code=JOR"], requested_endpoints
        assert_equal 1548, result[:api_team].api_id
        assert_equal "Jordan", result[:api_team].name
        assert_equal "JOR", result[:api_team].code
        assert_equal selecao, result[:api_team].selecao
      end
    end

    test "nao chama API quando selecao ja esta associada" do
      selecao = create_selecao!("Brasil")
      ApiFootballTeam.create!(
        api_id: 6,
        name: "Brazil",
        code: "BRA",
        selecao: selecao
      )

      ApiFootballClient.stub(:request, ->(_endpoint) { flunk "API nao deveria ser chamada" }) do
        result = Sync.new.sync_team(selecao.nome)

        assert result[:skipped]
        assert_match "já existe", result[:reason]
      end
    end

    test "proxima selecao pendente ignora selecoes especiais e associadas" do
      create_selecao!("A definir")
      create_selecao!("Provisório")
      argentina = create_selecao!("Argentina")
      brasil = create_selecao!("Brasil")

      Selecao
        .where.not(nome: ["A definir", "Provisório", "Argentina", "Brasil"])
        .find_each
        .with_index do |selecao, index|
          ApiFootballTeam.create!(
            api_id: 10_000 + index,
            name: "Associated #{index}",
            code: "T#{index}",
            selecao: selecao
          )
        end

      ApiFootballTeam.create!(
        api_id: 6,
        name: "Brazil",
        code: "BRA",
        selecao: brasil
      )

      assert_equal argentina, Sync.new.next_pending_selection
    end

    private

    def create_selecao!(nome)
      Selecao.create!(
        nome: nome,
        logo: "#{nome.parameterize}.png",
        grupo: @grupo
      )
    end
  end
end
