class AddTipoToJogos < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :tipo, :integer, default: 0, null: false
  end
end
