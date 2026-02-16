class AddFieldLigaIdInNotificacoes < ActiveRecord::Migration[7.1]
  def change
    add_column :notificacoes, :liga_id, :integer, null: false
  end
end
