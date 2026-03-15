require 'resend'

if Rails.env.production?
  ActionMailer::Base.delivery_method = :resend
  ActionMailer::Base.resend_settings = {
    api_key: ENV['RESEND_API_KEY']
  }
  ActionMailer::Base.default_url_options = { 
    host: ENV['RESEND_HOST'], 
    protocol: 'https' 
  }
end