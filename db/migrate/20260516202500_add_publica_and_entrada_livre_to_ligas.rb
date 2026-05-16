class AddPublicaAndEntradaLivreToLigas < ActiveRecord::Migration[7.1]
  def change
    add_column :ligas, :publica, :boolean, default: false, null: false
    add_column :ligas, :entrada_livre, :boolean, default: false, null: false
  end
end
