require "test_helper"

class PalpitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @palpite = palpites(:one)
  end

  test "should get index" do
    get palpites_url
    assert_response :success
  end

  test "should get new" do
    get new_palpite_url
    assert_response :success
  end

  test "should create palpite" do
    assert_difference("Palpite.count") do
      post palpites_url, params: { palpite: { gols_casa: @palpite.gols_casa, gols_fora: @palpite.gols_fora, jogo_id: @palpite.jogo_id, user_id: @palpite.user_id } }
    end

    assert_redirected_to palpite_url(Palpite.last)
  end

  test "should show palpite" do
    get palpite_url(@palpite)
    assert_response :success
  end

  test "should get edit" do
    get edit_palpite_url(@palpite)
    assert_response :success
  end

  test "should update palpite" do
    patch palpite_url(@palpite), params: { palpite: { gols_casa: @palpite.gols_casa, gols_fora: @palpite.gols_fora, jogo_id: @palpite.jogo_id, user_id: @palpite.user_id } }
    assert_redirected_to palpite_url(@palpite)
  end

  test "should destroy palpite" do
    assert_difference("Palpite.count", -1) do
      delete palpite_url(@palpite)
    end

    assert_redirected_to palpites_url
  end
end
