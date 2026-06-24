json.extract! selecao, :id, :nome, :pontos, :qtd_jogos, :vitorias, :derrotas, :empates, :logo, :created_at, :updated_at
json.url selecao_url(selecao, format: :json)
