require "net/http"
require "json"

module MercadoPago
  class ApiError < StandardError
    attr_reader :status, :response_body

    def initialize(message, status:, response_body:)
      super(message)
      @status = status
      @response_body = response_body
    end

    def create_payment(payload)
      response = connection.post("/v1/payments") do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
        req.headers["X-Idempotency-Key"] = SecureRandom.uuid

        req.body = payload.to_json
      end

      parse_response(response)
    end

    def user_message
      return credentials_environment_message if message.include?("Unauthorized use of live credentials")
      return missing_access_token_message if message.include?("Must provide your access_token")

      "Não foi possível gerar o Pix. Tente novamente em instantes."
    end

    private

    def credentials_environment_message
      "Credenciais do Mercado Pago incompatíveis com este teste. Confira se o Access Token veio da tela Credenciais de teste e se o pagador é um e-mail @testuser.com."
    end

    def missing_access_token_message
      "Access Token do Mercado Pago inválido. Confira se MERCADO_PAGO_ACCESS_TOKEN é o Access Token completo das credenciais, não a Public Key nem o Client Secret."
    end
  end

  class Client
    API_BASE_URL = "https://api.mercadopago.com".freeze

    def initialize(access_token: Config.access_token)
      @access_token = access_token.to_s.strip
    end

    def create_payment(payload, idempotency_key:)
      validate_access_token!

      request(
        method: Net::HTTP::Post,
        path: "/v1/payments",
        body: payload,
        headers: { "X-Idempotency-Key" => idempotency_key }
      )
    end

    def create_preference(payload, idempotency_key:)
      validate_access_token!

      request(
        method: Net::HTTP::Post,
        path: "/checkout/preferences",
        body: payload,
        headers: { "X-Idempotency-Key" => idempotency_key }
      )
    end

    def payment(payment_id)
      validate_access_token!

      request(
        method: Net::HTTP::Get,
        path: "/v1/payments/#{payment_id}"
      )
    end

    private

    attr_reader :access_token

    def validate_access_token!
      raise "#{Config.access_token_key} não configurado" if access_token.blank?
    end

    def request(method:, path:, body: nil, headers: {})
      uri = URI("#{API_BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = method.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request.body = body.to_json if body

      response = http.request(request)
      parsed_body = response.body.present? ? JSON.parse(response.body) : {}

      return parsed_body if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)

      message = parsed_body["message"] || parsed_body["error"] || response.message
      raise ApiError.new(
        "Mercado Pago retornou erro #{response.code}: #{message}",
        status: response.code.to_i,
        response_body: parsed_body
      )
    end
  end
end
