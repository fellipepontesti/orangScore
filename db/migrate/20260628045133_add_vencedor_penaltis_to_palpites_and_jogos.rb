class AddVencedorPenaltisToPalpitesAndJogos < ActiveRecord::Migration[7.1]
  def change
    add_column :palpites, :vencedor_penaltis_id, :bigint
    add_column :jogos, :vencedor_penaltis_id, :bigint

    add_foreign_key :palpites, :selecoes, column: :vencedor_penaltis_id
    add_foreign_key :jogos, :selecoes, column: :vencedor_penaltis_id

    add_index :palpites, :vencedor_penaltis_id
    add_index :jogos, :vencedor_penaltis_id
  end
end
