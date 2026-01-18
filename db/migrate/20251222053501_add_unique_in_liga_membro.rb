class AddUniqueInLigaMembro < ActiveRecord::Migration[7.1]
  def change
    add_index :liga_membros, [:liga_id, :user_id], unique: true

  end
end
