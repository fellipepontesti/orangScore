require "application_system_test_case"

class SelecaosTest < ApplicationSystemTestCase
  setup do
    @selecao = selecoes(:one)
  end

  test "visiting the index" do
    visit selecoes_url
    assert_selector "h1", text: "Selecaos"
  end

  test "should create selecao" do
    visit selecoes_url
    click_on "New selecao"

    fill_in "Derrotas", with: @selecao.derrotas
    fill_in "Empates", with: @selecao.empates
    fill_in "Jogos", with: @selecao.jogos
    fill_in "Logo", with: @selecao.logo
    fill_in "Nome", with: @selecao.nome
    fill_in "Pontos", with: @selecao.pontos
    fill_in "Vitorias", with: @selecao.vitorias
    click_on "Create Selecao"

    assert_text "Selecao was successfully created"
    click_on "Back"
  end

  test "should update Selecao" do
    visit selecao_url(@selecao)
    click_on "Edit this selecao", match: :first

    fill_in "Derrotas", with: @selecao.derrotas
    fill_in "Empates", with: @selecao.empates
    fill_in "Jogos", with: @selecao.jogos
    fill_in "Logo", with: @selecao.logo
    fill_in "Nome", with: @selecao.nome
    fill_in "Pontos", with: @selecao.pontos
    fill_in "Vitorias", with: @selecao.vitorias
    click_on "Update Selecao"

    assert_text "Selecao was successfully updated"
    click_on "Back"
  end

  test "should destroy Selecao" do
    visit selecao_url(@selecao)
    accept_confirm { click_on "Destroy this selecao", match: :first }

    assert_text "Selecao was successfully destroyed"
  end
end
