class DropApiFootballTeamsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :api_football_teams
  end
end
