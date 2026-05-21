class AddReferralCountedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :referral_counted_at, :datetime
  end
end
