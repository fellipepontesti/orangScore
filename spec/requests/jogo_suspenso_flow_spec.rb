require "rails_helper"

RSpec.describe "JogoSuspensoFlow", type: :request do
  let(:admin) { users(:one) }
  let(:user) { users(:two) }
  let(:jogo) { jogos(:one) }

  before do
    # Criar um operador semi_root
    @semi = User.find_by(email: "semi@orang.com.br")
    unless @semi
      @semi = User.new(
        name: "Operador Semi",
        email: "semi@orang.com.br",
        selecao: selecoes(:one),
        tipo: :semi_root,
        confirmed_at: Time.current,
        terms_accepted_at: Time.current,
        esconder_odds: false
      )
      @semi.password = "Semi#123"
      @semi.password_confirmation = "Semi#123"
      @semi.terms_of_service = "1"
      @semi.save!
    end

    jogo.update!(status: :programado, definir: false, gols_mandante: nil, gols_visitante: nil)

    # Garantir que o user tenha palpitado no jogo para receber notificações
    user.palpites.where(jogo: jogo).destroy_all
    user.notificacoes.destroy_all
    @palpite = Palpite.create!(
      user: user,
      jogo: jogo,
      gols_casa: 1,
      gols_fora: 0,
      uuid: SecureRandom.uuid
    )
  end

  it "completes game lifecycle flow by root and semi_root" do
    # 1. Iniciar o Jogo (como semi_root / operador)
    sign_in @semi
    expect {
      patch start_jogo_path(jogo)
    }.to change { jogo.reload.status }.from("programado").to("em_andamento")
    expect(response).to redirect_to(jogo_path(jogo))

    # Verificar que uma notificação foi gerada para o usuário palpitante
    expect(user.notificacoes.unread.count).to eq(1)
    notif_start = user.notificacoes.unread.last
    expect(notif_start.texto).to match("começou")

    # 2. Suspender o Jogo (como semi_root)
    expect {
      patch jogo_path(jogo), params: { jogo: { status: "suspenso" } }
    }.to change { jogo.reload.status }.from("em_andamento").to("suspenso")
    expect(response).to redirect_to(jogo_path(jogo))

    # Verificar notificação de jogo suspenso
    expect(user.notificacoes.unread.count).to eq(2)
    notif_suspenso = user.notificacoes.unread.last
    expect(notif_suspenso.texto).to match("suspenso")

    # 3. Retomar o Jogo (como root / admin)
    sign_in admin

    expect {
      patch jogo_path(jogo), params: { jogo: { status: "em_andamento" } }
    }.to change { jogo.reload.status }.from("suspenso").to("em_andamento")
    expect(response).to redirect_to(jogo_path(jogo))

    # Verificar notificação de jogo retomado
    expect(user.notificacoes.unread.count).to eq(3)
    notif_retomado = user.notificacoes.unread.last
    expect(notif_retomado.texto).to match("retomado")

    # 4. Finalizar o Jogo (como root / admin)
    expect {
      patch finish_jogo_path(jogo), params: { jogo: { gols_mandante: 2, gols_visitante: 1 } }
    }.to change { jogo.reload.status }.from("em_andamento").to("finalizado")
    expect(response).to redirect_to(jogo_path(jogo))

    # Verificar placar e notificação finalizada
    expect(jogo.reload.gols_mandante).to eq(2)
    expect(jogo.gols_visitante).to eq(1)
    
    expect(user.notificacoes.unread.count).to eq(4)
    notif_finalizado = user.notificacoes.unread.last
    expect(notif_finalizado.texto).to match("terminou")
  end
end
