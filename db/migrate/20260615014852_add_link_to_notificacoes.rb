class AddLinkToNotificacoes < ActiveRecord::Migration[7.1]
  def change
    add_column :notificacoes, :link, :string
  end
end
