class CreateJogadores < ActiveRecord::Migration[7.1]
  def change
    create_table :jogadores do |t|
      t.belongs_to :selecao, null: false, foreign_key: { to_table: :selecoes }
      t.string :nome, null: false
      t.integer :numero
      t.string :posicao
      t.date :data_nascimento
      t.integer :idade_torneio
      t.string :clube
      t.string :clube_pais
      t.boolean :capitao, default: false, null: false
      t.integer :gols, default: 0, null: false
      t.uuid :uuid, null: false

      t.timestamps
    end
  end
end
