class AddTypeInUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :tipo, :integer, default: 0
  end
end
