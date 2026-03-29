class AddStatusInJogo < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :status, :integer, default: 0
  end
end
