class AddAssistenciasToJogadores < ActiveRecord::Migration[7.1]
  def change
    add_column :jogadores, :assistencias, :integer, default: 0, null: false
  end
end
