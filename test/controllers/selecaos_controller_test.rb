require "test_helper"

class SelecaosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @selecao = selecoes(:one)
  end

  test "should get index" do
    get selecoes_url
    assert_response :success
  end

  test "should get new" do
    get new_selecao_url
    assert_response :success
  end

  test "should create selecao" do
    assert_difference("Selecao.count") do
      post selecoes_url, params: { selecao: { derrotas: @selecao.derrotas, empates: @selecao.empates, jogos: @selecao.jogos, logo: @selecao.logo, nome: @selecao.nome, pontos: @selecao.pontos, vitorias: @selecao.vitorias } }
    end

    assert_redirected_to selecao_url(Selecao.last)
  end

  test "should show selecao" do
    get selecao_url(@selecao)
    assert_response :success
  end

  test "should get edit" do
    get edit_selecao_url(@selecao)
    assert_response :success
  end

  test "should update selecao" do
    patch selecao_url(@selecao), params: { selecao: { derrotas: @selecao.derrotas, empates: @selecao.empates, jogos: @selecao.jogos, logo: @selecao.logo, nome: @selecao.nome, pontos: @selecao.pontos, vitorias: @selecao.vitorias } }
    assert_redirected_to selecao_url(@selecao)
  end

  test "should destroy selecao" do
    assert_difference("Selecao.count", -1) do
      delete selecao_url(@selecao)
    end

    assert_redirected_to selecoes_url
  end
end
