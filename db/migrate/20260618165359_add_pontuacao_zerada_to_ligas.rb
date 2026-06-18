class AddPontuacaoZeradaToLigas < ActiveRecord::Migration[7.1]
  def change
    add_column :ligas, :pontuacao_zerada, :boolean, default: false, null: false
  end
end
