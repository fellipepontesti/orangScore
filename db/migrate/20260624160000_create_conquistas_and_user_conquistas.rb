class CreateConquistasAndUserConquistas < ActiveRecord::Migration[7.1]
  def change
    create_table :conquistas do |t|
      t.string :nome, null: false
      t.string :descricao, null: false
      t.string :slug, null: false
      t.string :icon, null: false
      t.string :cor, null: false
      t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false

      t.timestamps
    end
    add_index :conquistas, :slug, unique: true
    add_index :conquistas, :uuid, unique: true

    create_table :user_conquistas do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conquista, null: false, foreign_key: { to_table: :conquistas }
      t.references :jogo, null: true, foreign_key: true
      t.boolean :destacada, default: false, null: false
      t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false

      t.timestamps
    end
    add_index :user_conquistas, :uuid, unique: true
    add_index :user_conquistas, [:user_id, :conquista_id], unique: true
  end
end
