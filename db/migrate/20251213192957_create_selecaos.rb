class CreateSelecaos < ActiveRecord::Migration[7.1]
  def change
    create_table :selecoes do |t|
      t.string :nome
      t.integer :pontos
      t.integer :jogos
      t.integer :vitorias
      t.integer :derrotas
      t.integer :empates
      t.string :logo

      t.timestamps
    end
  end
end
