class CreateLigas < ActiveRecord::Migration[7.1]
  def change
    create_table :ligas do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :nome

      t.timestamps
    end
  end
end
