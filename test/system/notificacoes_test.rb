require "application_system_test_case"

class NotificacoesTest < ApplicationSystemTestCase
  setup do
    @notificacao = notificacoes(:one)
  end

  test "visiting the index" do
    visit notificacoes_url
    assert_selector "h1", text: "Notificacoes"
  end

  test "should create notificacao" do
    visit notificacoes_url
    click_on "New notificacao"

    fill_in "Sender", with: @notificacao. sender_id
    fill_in "Status", with: @notificacao. status
    fill_in "Text", with: @notificacao. text
    fill_in "Integer", with: @notificacao.integer
    fill_in "Text", with: @notificacao.text
    fill_in "Tipo", with: @notificacao.tipo
    fill_in "User", with: @notificacao.user_id
    click_on "Create Notificacao"

    assert_text "Notificacao was successfully created"
    click_on "Back"
  end

  test "should update Notificacao" do
    visit notificacao_url(@notificacao)
    click_on "Edit this notificacao", match: :first

    fill_in "Sender", with: @notificacao. sender_id
    fill_in "Status", with: @notificacao. status
    fill_in "Text", with: @notificacao. text
    fill_in "Integer", with: @notificacao.integer
    fill_in "Text", with: @notificacao.text
    fill_in "Tipo", with: @notificacao.tipo
    fill_in "User", with: @notificacao.user_id
    click_on "Update Notificacao"

    assert_text "Notificacao was successfully updated"
    click_on "Back"
  end

  test "should destroy Notificacao" do
    visit notificacao_url(@notificacao)
    accept_confirm { click_on "Destroy this notificacao", match: :first }

    assert_text "Notificacao was successfully destroyed"
  end
end
