require "application_system_test_case"

class PalpitesTest < ApplicationSystemTestCase
  setup do
    @palpite = palpites(:one)
  end

  test "visiting the index" do
    visit palpites_url
    assert_selector "h1", text: "Palpites"
  end

  test "should create palpite" do
    visit palpites_url
    click_on "New palpite"

    fill_in "Gols casa", with: @palpite.gols_casa
    fill_in "Gols fora", with: @palpite.gols_fora
    fill_in "Jogo", with: @palpite.jogo_id
    fill_in "User", with: @palpite.user_id
    click_on "Create Palpite"

    assert_text "Palpite was successfully created"
    click_on "Back"
  end

  test "should update Palpite" do
    visit palpite_url(@palpite)
    click_on "Edit this palpite", match: :first

    fill_in "Gols casa", with: @palpite.gols_casa
    fill_in "Gols fora", with: @palpite.gols_fora
    fill_in "Jogo", with: @palpite.jogo_id
    fill_in "User", with: @palpite.user_id
    click_on "Update Palpite"

    assert_text "Palpite was successfully updated"
    click_on "Back"
  end

  test "should destroy Palpite" do
    visit palpite_url(@palpite)
    accept_confirm { click_on "Destroy this palpite", match: :first }

    assert_text "Palpite was successfully destroyed"
  end
end
