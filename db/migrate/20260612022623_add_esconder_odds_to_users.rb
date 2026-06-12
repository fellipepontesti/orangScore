class AddEsconderOddsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :esconder_odds, :boolean, default: false, null: false
  end
end
