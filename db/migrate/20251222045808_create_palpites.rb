class CreatePalpites < ActiveRecord::Migration[7.1]
  def change
    create_table :palpites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :jogo, null: false, foreign_key: true

      t.integer :gols_casa, null: false
      t.integer :gols_fora, null: false

      t.timestamps
    end

    add_index :palpites, [:user_id, :jogo_id], unique: true
  end
end