class RenameSelecaosToSelecoes < ActiveRecord::Migration[7.1]
  def change
    rename_table :selecoes, :selecoes
  end
end
