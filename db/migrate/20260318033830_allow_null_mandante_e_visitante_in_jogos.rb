class AllowNullMandanteEVisitanteInJogos < ActiveRecord::Migration[7.1]
  def change
    change_column_null :jogos, :mandante_id, true
    change_column_null :jogos, :visitante_id, true
  end
end
