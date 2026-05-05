class ApplicationMailer < ActionMailer::Base
  helper_method :app_url
  default from: 'no-reply@orangscore.com.br'
  layout "mailer"

  def app_url
    "https://#{ENV.fetch('APP_HOST', 'orangscore.com.br')}"
  end

  def default_url_options
    {
      host: 'orangscore.com.br',
      protocol: 'https'
    }
  end
end
