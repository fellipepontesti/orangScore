class AddFieldQtdTorcedoresSelecao < ActiveRecord::Migration[7.1]
  def change
    add_column :selecoes, :qtd_torcedores, :bigint, default: 0
  end
end
