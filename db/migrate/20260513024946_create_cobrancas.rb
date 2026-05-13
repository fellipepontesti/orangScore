class CreateCobrancas < ActiveRecord::Migration[7.1]
  def change
    create_table :cobrancas do |t|
      t.references :user, null: false, foreign_key: true

      t.string :plano, null: false
      t.integer :valor, null: false

      t.integer :status, null: false, default: 0

      t.string :gateway, null: false
      t.string :gateway_cobranca_id
      t.string :gateway_checkout_url

      t.string :payment_method, null: false

      t.datetime :expires_at
      t.datetime :paid_at

      t.timestamps
    end

    add_index :cobrancas, :gateway_cobranca_id
    add_index :cobrancas, :status
  end
end