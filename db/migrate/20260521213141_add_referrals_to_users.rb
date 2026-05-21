class AddReferralsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :referred_by_id, :integer
    add_column :users, :referrals_count, :integer, default: 0
  end
end
