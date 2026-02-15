class PasswordMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    @token = token
    mail(to: @user.email, subject: 'Recuperação de senha')
  end
end
