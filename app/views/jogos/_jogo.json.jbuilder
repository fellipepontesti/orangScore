json.extract! jogo, :id, :mandante_id, :visitante_id, :gols_mandante, :gols_visitante, :data, :created_at, :updated_at
json.url jogo_url(jogo, format: :json)
