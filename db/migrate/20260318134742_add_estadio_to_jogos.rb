class AddEstadioToJogos < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :estadio, :string
    add_column :jogos, :nome_provisorio_mandante, :string
    add_column :jogos, :nome_provisorio_visitante, :string
  end
end
