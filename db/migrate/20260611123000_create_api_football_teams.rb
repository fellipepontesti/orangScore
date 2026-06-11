class CreateApiFootballTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :api_football_teams do |t|
      t.integer :api_id, null: false
      t.string :name, null: false
      t.string :country
      t.string :code
      t.string :logo
      t.integer :founded
      t.string :city
      t.references :selecao, foreign_key: true, index: true, null: true

      t.timestamps
    end

    add_index :api_football_teams, :api_id, unique: true
    add_index :api_football_teams, :name
  end
end
