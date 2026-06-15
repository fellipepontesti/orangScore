module Notificacoes
  class Broadcast
    attr_reader :texto, :sender

    def initialize(texto:, sender:, link:)
      @texto = texto.to_s.strip
      @sender = sender
      @link = link
    end

    def call
      raise ActiveRecord::RecordInvalid, notification unless notification.valid?

      created_count = 0

      ActiveRecord::Base.transaction do
        User.find_each do |user|
          Notificacao.create!(
            user: user,
            sender: sender,
            texto: texto,
            tipo: :system,
            status: :unread,
            link: @link
          )

          created_count += 1
        end
      end

      created_count
    end

    private

    def notification
      @notification ||= Notificacao.new(
        user: sender,
        sender: sender,
        texto: texto,
        tipo: :system,
        status: :unread
      )
    end
  end
end
