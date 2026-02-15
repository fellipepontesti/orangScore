class PasswordMailerPreview < ActionMailer::Preview
  def reset
    user = User.first
    token = 'token-de-teste'
    PasswordMailer.reset(user, token)
  end
end