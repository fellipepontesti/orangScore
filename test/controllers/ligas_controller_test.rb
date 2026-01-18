require "test_helper"

class LigasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @liga = ligas(:one)
  end

  test "should get index" do
    get ligas_url
    assert_response :success
  end

  test "should get new" do
    get new_liga_url
    assert_response :success
  end

  test "should create liga" do
    assert_difference("Liga.count") do
      post ligas_url, params: { liga: { nome: @liga.nome, owner_id: @liga.owner_id } }
    end

    assert_redirected_to liga_url(Liga.last)
  end

  test "should show liga" do
    get liga_url(@liga)
    assert_response :success
  end

  test "should get edit" do
    get edit_liga_url(@liga)
    assert_response :success
  end

  test "should update liga" do
    patch liga_url(@liga), params: { liga: { nome: @liga.nome, owner_id: @liga.owner_id } }
    assert_redirected_to liga_url(@liga)
  end

  test "should destroy liga" do
    assert_difference("Liga.count", -1) do
      delete liga_url(@liga)
    end

    assert_redirected_to ligas_url
  end
end
