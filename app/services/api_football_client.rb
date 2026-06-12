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

        # Detecta erros da API que indicam que devemos tentar a próxima chave:
        # - rateLimit: limite de requisições atingido para esta chave
        # - access: conta suspensa
        # - token: chave inválida
        if body.is_a?(Hash) && body['errors'].is_a?(Hash)
          errors = body['errors']
          if errors['rateLimit'] || errors['access'] || errors['token']
            Rails.logger.warn("API-Football: erro com chave #{key[0..4]}...: #{errors.inspect}")
            next
          end
        end

        return body
      end
      # All keys exhausted or failed
      nil
    end
  end
end
