class AddDefaultsToSelecaos < ActiveRecord::Migration[7.1]
  def change
    change_column_default :selecoes, :pontos, 0
    change_column_default :selecoes, :jogos, 0
    change_column_default :selecoes, :vitorias, 0
    change_column_default :selecoes, :derrotas, 0
    change_column_default :selecoes, :empates, 0
  end
end
