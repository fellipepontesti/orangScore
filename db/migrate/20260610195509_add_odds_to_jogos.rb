class AddOddsToJogos < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :prob_mandante, :integer
    add_column :jogos, :prob_empate, :integer
    add_column :jogos, :prob_visitante, :integer
  end
end
