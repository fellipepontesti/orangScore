class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@orangscore.com.br'
  layout "mailer"

  def default_url_options
    {
      host: 'orangscore.com.br',
      protocol: 'https'
    }
  end
end
