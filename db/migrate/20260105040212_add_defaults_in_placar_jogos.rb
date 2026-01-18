class AddDefaultsInPlacarJogos < ActiveRecord::Migration[7.1]
  def change
    change_column_default :jogos, :gols_mandante, 0
    change_column_default :jogos, :gols_visitante, 0
  end
end
