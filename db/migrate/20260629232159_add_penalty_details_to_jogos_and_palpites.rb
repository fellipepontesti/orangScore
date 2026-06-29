class AddPenaltyDetailsToJogosAndPalpites < ActiveRecord::Migration[7.1]
  def change
    add_column :jogos, :gols_penaltis_mandante, :integer
    add_column :jogos, :gols_penaltis_visitante, :integer
    add_column :jogos, :sequencia_penaltis_mandante, :string
    add_column :jogos, :sequencia_penaltis_visitante, :string

    add_column :palpites, :gols_penaltis_casa, :integer
    add_column :palpites, :gols_penaltis_fora, :integer
  end
end
