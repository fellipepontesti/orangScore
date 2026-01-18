class AddFieldsGolsInSelecoes < ActiveRecord::Migration[7.1]
  def change
    add_column :selecoes, :gols, :bigint, default: 0
    add_column :selecoes, :gols_sofridos, :bigint, default: 0
  end
end
