class AddCobrancaToPagamentos < ActiveRecord::Migration[7.1]
  def change
    add_reference :pagamentos, :cobranca, null: false, foreign_key: true
  end
end
