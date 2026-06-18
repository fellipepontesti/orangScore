class CreateInformacaoJogos < ActiveRecord::Migration[7.1]
  def change
    create_table :informacao_jogos do |t|
      t.references :jogo, null: false, foreign_key: true
      t.json :dados

      t.timestamps
    end
  end
end
