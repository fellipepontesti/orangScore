class AddStatusAndRoleInLigaMembro < ActiveRecord::Migration[7.1]
  def change
    add_column :liga_membros, :status, :integer
    add_column :liga_membros, :role, :integer
  end
end
