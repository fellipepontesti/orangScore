class AddQtdMembrosInLiga < ActiveRecord::Migration[7.1]
  def change
    add_column :ligas, :membros, :integer, null: false, default: 0
  end
end
