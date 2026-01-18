class AddLogoSelecaoAndPontuacaoInUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :logo_selecao, :string
    add_column :users, :pontos, :integer
  end
end
