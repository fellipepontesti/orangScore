module Emails
  class Broadcast
    attr_reader :assunto, :mensagem, :sender

    def initialize(assunto:, mensagem:, sender:)
      @assunto = assunto.to_s.strip
      @mensagem = mensagem.to_s.strip
      @sender = sender
    end

    def call
      validate!

      sent_count = 0

      User.find_each do |user|
        next if user.email.blank?

        BroadcastMailer.with(
          user_email: user.email,
          user_name: user.name,
          assunto: assunto,
          mensagem: mensagem,
          sender_email: sender.email,
          sender_name: sender.name
        ).broadcast_email.deliver_later

        sent_count += 1
      end

      sent_count
    end

    private

    def validate!
      raise ArgumentError, "O assunto não pode ficar em branco" if assunto.blank?
      raise ArgumentError, "A mensagem não pode ficar em branco" if mensagem.blank?
    end
  end
end
