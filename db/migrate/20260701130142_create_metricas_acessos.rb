class CreateMetricasAcessos < ActiveRecord::Migration[7.1]
  def change
    create_table :metricas_acessos do |t|
      t.string :key, null: false
      t.string :nome, null: false
      t.integer :acessos, default: 0, null: false

      t.timestamps
    end
    add_index :metricas_acessos, :key, unique: true
  end
end
