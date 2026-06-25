require "rails_helper"

RSpec.describe Users::AwardAchievements, type: :service do
  let(:user) { users(:one) }
  let(:jogo) { jogos(:one) }

  before do
    Conquista.find_or_create_by!(slug: 'primeiro_palpite') do |c|
      c.nome = 'Chute Inicial'
      c.descricao = 'Fez o seu primeiro palpite.'
      c.icon = '⚽'
      c.cor = 'bg-info'
    end
    Conquista.find_or_create_by!(slug: 'pontos_10') do |c|
      c.nome = 'Profeta do Placar'
      c.descricao = 'Acertou em cheio.'
      c.icon = '🏆'
      c.cor = 'bg-warning'
    end
  end

  describe ".award" do
    it "concede conquista ao usuario apenas uma vez" do
      expect {
        Users::AwardAchievements.award(user, 'primeiro_palpite')
      }.to change(UserConquista, :count).by(1)

      expect {
        Users::AwardAchievements.award(user, 'primeiro_palpite')
      }.not_to change(UserConquista, :count)
    end
  end

  describe ".check_palpite_achievements" do
    it "concede a conquista primeiro_palpite quando o usuario faz um palpite" do
      # Remove any existing palpites in user fixture to start fresh
      user.palpites.destroy_all
      
      Palpite.create!(user: user, jogo: jogo, gols_casa: 2, gols_fora: 1)
      
      expect {
        Users::AwardAchievements.check_palpite_achievements(user)
      }.to change(user.conquistas, :count).by(1)
      
      expect(user.conquistas.first.slug).to eq('primeiro_palpite')
    end
  end

  describe "validação de limite de destaques" do
    it "impede usuario basico de destacar mais de 1 conquista" do
      c1 = Conquista.find_by(slug: 'primeiro_palpite')
      c2 = Conquista.find_by(slug: 'pontos_10')

      uc1 = UserConquista.create!(user: user, conquista: c1)
      uc2 = UserConquista.create!(user: user, conquista: c2)

      # Plano básico
      if user.assinatura
        user.assinatura.update!(plano: :basic)
      else
        Assinatura.create!(usuario: user, plano: :basic, ativa: true)
      end
      user.reload
      
      uc1.update!(destacada: true)
      expect(uc1.valid?).to be_truthy

      uc2.destacada = true
      expect(uc2.valid?).to be_falsey
      expect(uc2.errors[:destacada]).to include(/Limite de conquistas em destaque atingido/)
    end

    it "permite usuario premium destacar ate 3 conquistas" do
      c1 = Conquista.find_by(slug: 'primeiro_palpite')
      c2 = Conquista.find_by(slug: 'pontos_10')
      c3 = Conquista.create!(nome: 'Test', descricao: 'Test', slug: 'test', icon: '⭐', cor: 'bg-pink')

      uc1 = UserConquista.create!(user: user, conquista: c1)
      uc2 = UserConquista.create!(user: user, conquista: c2)
      uc3 = UserConquista.create!(user: user, conquista: c3)

      # Plano premium
      if user.assinatura
        user.assinatura.update!(plano: :premium)
      else
        Assinatura.create!(usuario: user, plano: :premium, ativa: true)
      end
      user.reload
      
      uc1.update!(destacada: true)
      uc2.update!(destacada: true)
      uc3.destacada = true
      expect(uc3.valid?).to be_truthy
    end
  end
end
