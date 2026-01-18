class CreateLigaMembros < ActiveRecord::Migration[7.1]
  def change
    create_table :liga_membros do |t|
      t.references :liga, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
