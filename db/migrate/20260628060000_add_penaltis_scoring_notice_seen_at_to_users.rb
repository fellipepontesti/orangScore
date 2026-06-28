class AddPenaltisScoringNoticeSeenAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :penaltis_scoring_notice_seen_at, :datetime
  end
end
