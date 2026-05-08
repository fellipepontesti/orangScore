class AddInviteTokenToLigas < ActiveRecord::Migration[7.1]
  def change
    add_column :ligas, :invite_token, :string
    add_index :ligas, :invite_token, unique: true
  end
end