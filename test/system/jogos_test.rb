require "application_system_test_case"

class JogosTest < ApplicationSystemTestCase
  setup do
    @jogo = jogos(:one)
  end

  test "visiting the index" do
    visit jogos_url
    assert_selector "h1", text: "Jogos"
  end

  test "should create jogo" do
    visit jogos_url
    click_on "New jogo"

    fill_in "Data", with: @jogo.data
    fill_in "Gols mandante", with: @jogo.gols_mandante
    fill_in "Gols visitante", with: @jogo.gols_visitante
    fill_in "Mandante", with: @jogo.mandante_id
    fill_in "Visitante", with: @jogo.visitante_id
    click_on "Create Jogo"

    assert_text "Jogo was successfully created"
    click_on "Back"
  end

  test "should update Jogo" do
    visit jogo_url(@jogo)
    click_on "Edit this jogo", match: :first

    fill_in "Data", with: @jogo.data
    fill_in "Gols mandante", with: @jogo.gols_mandante
    fill_in "Gols visitante", with: @jogo.gols_visitante
    fill_in "Mandante", with: @jogo.mandante_id
    fill_in "Visitante", with: @jogo.visitante_id
    click_on "Update Jogo"

    assert_text "Jogo was successfully updated"
    click_on "Back"
  end

  test "should destroy Jogo" do
    visit jogo_url(@jogo)
    accept_confirm { click_on "Destroy this jogo", match: :first }

    assert_text "Jogo was successfully destroyed"
  end
end
