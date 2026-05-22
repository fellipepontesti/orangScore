json.extract! liga, :uuid, :nome, :created_at, :updated_at
json.owner_uuid liga.owner.uuid
json.url liga_url(liga, format: :json)
