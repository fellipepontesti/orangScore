class AddGrupoToJogos < ActiveRecord::Migration[7.1]
  def change
    add_reference :jogos, :grupo, null: true, foreign_key: true
  end
end