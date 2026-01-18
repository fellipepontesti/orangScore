require "application_system_test_case"

class LigasTest < ApplicationSystemTestCase
  setup do
    @liga = ligas(:one)
  end

  test "visiting the index" do
    visit ligas_url
    assert_selector "h1", text: "Ligas"
  end

  test "should create liga" do
    visit ligas_url
    click_on "New liga"

    fill_in "Nome", with: @liga.nome
    fill_in "Owner", with: @liga.owner_id
    click_on "Create Liga"

    assert_text "Liga was successfully created"
    click_on "Back"
  end

  test "should update Liga" do
    visit liga_url(@liga)
    click_on "Edit this liga", match: :first

    fill_in "Nome", with: @liga.nome
    fill_in "Owner", with: @liga.owner_id
    click_on "Update Liga"

    assert_text "Liga was successfully updated"
    click_on "Back"
  end

  test "should destroy Liga" do
    visit liga_url(@liga)
    accept_confirm { click_on "Destroy this liga", match: :first }

    assert_text "Liga was successfully destroyed"
  end
end
