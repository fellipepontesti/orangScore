class AddGrupoToSelecaos < ActiveRecord::Migration[7.1]
  def change
    add_reference :selecoes, :grupo, null: false, foreign_key: true
  end
end
