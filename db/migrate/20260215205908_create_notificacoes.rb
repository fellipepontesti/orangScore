class CreateNotificacoes < ActiveRecord::Migration[7.1]
  def change
    create_table :notificacoes do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :tipo
      t.integer :sender_id
      t.text :texto
      t.integer :status

      t.timestamps
    end
  end
end
