class CreateAssinaturas < ActiveRecord::Migration[7.1]
  def change
    create_table :assinaturas do |t|
      t.references :usuario,
                   null: false,
                   foreign_key: { to_table: :users }

      t.integer :plano,
                null: false,
                default: 0

      t.boolean :ativa,
                null: false,
                default: true

      t.datetime :data_expiracao

      t.timestamps
    end

    User.find_each do |usuario|
      Assinatura.create!(
        usuario_id: usuario.id,
        plano: :basic
      )
    end
  end
end
