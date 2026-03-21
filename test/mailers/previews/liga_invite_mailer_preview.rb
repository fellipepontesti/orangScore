# Preview all emails at http://localhost:3000/rails/mailers/liga_invite_mailer
class LigaInviteMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/liga_invite_mailer/invite_member
  def invite_member
    LigaInviteMailer.invite_member
  end

end
