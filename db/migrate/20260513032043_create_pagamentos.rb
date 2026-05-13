class CreatePagamentos < ActiveRecord::Migration[7.1]
  def change
    create_table :pagamentos do |t|
      t.references :user, null: false, foreign_key: true

      t.string :stripe_payment_intent_id
      t.string :stripe_customer_id
      t.string :stripe_invoice_id

      t.integer :valor, null: false

      t.integer :status, null: false, default: 0

      t.string :plano
      t.datetime :pago_em

      t.jsonb :metadata

      t.timestamps
    end

    add_index :pagamentos, :stripe_payment_intent_id, unique: true
    add_index :pagamentos, :stripe_invoice_id
    add_index :pagamentos, :status
  end
end