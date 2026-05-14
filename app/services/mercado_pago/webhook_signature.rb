require "openssl"

module MercadoPago
  class WebhookSignature
    def self.valid?(data_id:, request_id:, signature:, secret:)
      return true if secret.blank?
      return false if data_id.blank? || request_id.blank? || signature.blank?

      parts = signature.to_s.split(",").filter_map do |part|
        key, value = part.split("=", 2).map(&:strip)
        [key, value] if key.present? && value.present?
      end.to_h

      timestamp = parts["ts"]
      received_hash = parts["v1"]
      return false if timestamp.blank? || received_hash.blank?

      manifest = "id:#{data_id};request-id:#{request_id};ts:#{timestamp};"
      expected_hash = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)

      ActiveSupport::SecurityUtils.secure_compare(expected_hash, received_hash)
    end
  end
end
