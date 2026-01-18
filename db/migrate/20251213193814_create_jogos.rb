class CreateJogos < ActiveRecord::Migration[7.1]
  def change
    create_table :jogos do |t|
      t.references :mandante, null: false, foreign_key: { to_table: :selecoes }
      t.references :visitante, null: false, foreign_key: { to_table: :selecoes }
      t.integer :gols_mandante
      t.integer :gols_visitante
      t.datetime :data

      t.timestamps
    end
  end
end
