class EditNameFieldJogosInSelecao < ActiveRecord::Migration[7.1]
  def change
    rename_column :selecoes, :jogos, :qtd_jogos
  end
end
