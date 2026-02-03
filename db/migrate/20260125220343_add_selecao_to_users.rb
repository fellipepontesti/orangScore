class AddSelecaoToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :selecao, foreign_key: true
  end
end
