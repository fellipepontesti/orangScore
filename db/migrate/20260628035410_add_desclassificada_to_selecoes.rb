class AddDesclassificadaToSelecoes < ActiveRecord::Migration[7.1]
  def change
    add_column :selecoes, :desclassificada, :boolean, default: false, null: false
  end
end
