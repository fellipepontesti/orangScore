class AddVisualizadaToUserConquistas < ActiveRecord::Migration[7.1]
  def change
    add_column :user_conquistas, :visualizada, :boolean, default: false, null: false
  end
end
