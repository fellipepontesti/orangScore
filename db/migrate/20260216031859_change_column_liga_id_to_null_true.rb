class ChangeColumnLigaIdToNullTrue < ActiveRecord::Migration[7.1]
  def change
    change_column_null :notificacoes, :liga_id, true
  end
end
