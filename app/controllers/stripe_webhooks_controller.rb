class StripeWebhooksController < ApplicationController
  # Webhooks não possuem sessão de usuário ou token CSRF
  skip_before_action :authenticate_user!
  skip_before_action :check_terms_acceptance, raise: false
  skip_before_action :verify_authenticity_token
  
  # Força o Rails a tratar a requisição como JSON, evitando o erro de "Processing as XML"
  before_action :set_request_format

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error "⚠️ Falha na verificação do Webhook Stripe: #{e.message}"
      return head :bad_request
    end

    # Lógica para o evento de checkout concluído
    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      
      # Debug: Isso ajuda a ver no terminal se o metadata está chegando
      Rails.logger.info "🔔 Sessão do Stripe recebida: #{session.id}"
      Rails.logger.info "📦 ID da Cobrança no Metadata: #{session.metadata.cobranca_id}"

      cobranca = Cobranca.find_by(id: session.metadata.cobranca_id)
      
      if cobranca
        # Instancia e chama o seu service de confirmação
        Cobrancas::Confirmar.new(cobranca: cobranca, session: session).call
        Rails.logger.info "✅ Cobrança ##{cobranca.id} confirmada e plano ativado!"
      else
        Rails.logger.error "❌ Cobrança não encontrada para o ID: #{session.metadata.cobranca_id}"
      end
    else
      # Opcional: Logar outros tipos de eventos se desejar
      Rails.logger.info "ℹ️ Evento ignorado: #{event.type}"
    end

    head :ok
  rescue => e
    # Captura erros inesperados para não deixar o Stripe no vácuo com erro 500 sem log
    Rails.logger.error "💥 Erro Crítico no Webhook: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    head :internal_server_error
  end

  private

  def set_request_format
    request.format = :json
  end
end