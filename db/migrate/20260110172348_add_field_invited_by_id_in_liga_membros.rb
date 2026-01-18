class AddFieldInvitedByIdInLigaMembros < ActiveRecord::Migration[7.1]
  def change
    add_column :liga_membros, :invited_by_id, :bigint, default: nil
  end
end
