class AddDefaultsToGrupos < ActiveRecord::Migration[7.1]
  def change
    change_column_default :grupos, :rodadas, 0
  end
end
