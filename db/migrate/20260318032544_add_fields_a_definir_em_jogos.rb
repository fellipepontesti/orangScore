class AddFieldsADefinirEmJogos < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :definir, :boolean, default: false, null: false
  end
end
