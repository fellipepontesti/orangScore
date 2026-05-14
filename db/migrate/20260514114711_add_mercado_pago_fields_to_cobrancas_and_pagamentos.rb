class AddMercadoPagoFieldsToCobrancasAndPagamentos < ActiveRecord::Migration[7.1]
  def change
    add_column :cobrancas, :pix_qr_code, :text
    add_column :cobrancas, :pix_qr_code_base64, :text
    add_column :cobrancas, :gateway_status, :string

    add_column :pagamentos, :mercado_pago_payment_id, :string
    add_index :pagamentos, :mercado_pago_payment_id, unique: true
  end
end
