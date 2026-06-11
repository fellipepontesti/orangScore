require 'net/http'
require 'json'

module ApiFootballClient
  BASE_URL = 'https://v3.football.api-sports.io'
  # Load up to three keys from environment variables
  KEYS = [
    ENV['API_FOOTBALL_KEY_1'],
    ENV['API_FOOTBALL_KEY_2'],
    ENV['API_FOOTBALL_KEY_3']
  ].compact

  class << self
    def request(endpoint)
      raise 'Nenhuma chave API_FOOTBALL configurada.' if KEYS.empty?

      KEYS.each do |key|
        uri = URI("#{BASE_URL}#{endpoint}")
        req = Net::HTTP::Get.new(uri)
        req['x-apisports-key'] = key
        begin
          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end
        rescue => e
          Rails.logger.error("Erro na requisição da API-Football com chave #{key}: #{e.message}")
          next
        end

        # If not a success response, continue to next key
        next unless res.is_a?(Net::HTTPSuccess)

        body = JSON.parse(res.body)
        # Detect rate limit error structure from API
        if body.is_a?(Hash) && body['errors'] && body['errors']['requests']
          # Rate limit reached for this key, try next one
          next
        end
        return body
      end
      # All keys exhausted or failed
      nil
    end
  end
end
