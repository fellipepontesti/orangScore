json.extract! jogo, :uuid, :gols_mandante, :gols_visitante, :data, :created_at, :updated_at
json.grupo_uuid jogo.grupo&.uuid
json.url jogo_url(jogo, format: :json)
