class AddFieldAnswerInNotificacao < ActiveRecord::Migration[7.1]
  def change
    add_column :notificacoes, :answered, :boolean, default: true
  end
end
