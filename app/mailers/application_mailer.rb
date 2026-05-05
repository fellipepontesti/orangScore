class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@orangscore.com.br'
  layout "mailer"

  def app_url
    ENV.fetch('APP_URL', 'https://orangscore.com.br')
  end

  def default_url_options
    {
      host: 'orangscore.com.br',
      protocol: 'https'
    }
  end
end
