require "rails_helper"

RSpec.describe LigaInviteMailer, type: :mailer do
  describe "invite_member" do
    let(:user) { users(:two) }
    let(:liga) { ligas(:one) }
    let(:invited_by) { users(:one) }
    let(:mail) { LigaInviteMailer.with(user: user, liga: liga, invited_by: invited_by).invite_member }

    it "renders the headers" do
      expect(mail.subject).to eq("Você recebeu um convite para participar da liga #{liga.nome}")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.text_part.body.decoded).to match("Olá")
      expect(mail.html_part.body.decoded).to match("Olá")
    end
  end
end
