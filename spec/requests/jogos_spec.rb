require "rails_helper"

RSpec.describe "Jogos", type: :request do
  let(:user) { users(:one) }
  let(:jogo) { jogos(:one) }

  before do
    sign_in user
  end

  it "should get index" do
    get jogos_path
    expect(response).to have_http_status(:success)
  end

  it "should get new" do
    get new_jogo_path
    expect(response).to have_http_status(:success)
  end

  it "should create jogo" do
    expect {
      post jogos_path, params: { jogo: { data: jogo.data, gols_mandante: jogo.gols_mandante, gols_visitante: jogo.gols_visitante, mandante_id: jogo.mandante_id, visitante_id: jogo.visitante_id, tipo: jogo.tipo, grupo_id: jogo.grupo_id, definir: false } }
    }.to change(Jogo, :count).by(1)

    expect(response).to redirect_to(jogo_path(Jogo.last))
  end

  it "should show jogo" do
    get jogo_path(jogo)
    expect(response).to have_http_status(:success)
  end

  it "should get edit" do
    get edit_jogo_path(jogo)
    expect(response).to have_http_status(:success)
  end

  it "should update jogo" do
    patch jogo_path(jogo), params: { jogo: { data: jogo.data, gols_mandante: jogo.gols_mandante, gols_visitante: jogo.gols_visitante, mandante_id: jogo.mandante_id, visitante_id: jogo.visitante_id, tipo: jogo.tipo, grupo_id: jogo.grupo_id, definir: false } }
    expect(response).to redirect_to(jogo_path(jogo))
  end

  it "should destroy jogo" do
    expect {
      delete jogo_path(jogo)
    }.to change(Jogo, :count).by(-1)

    expect(response).to redirect_to(jogos_path)
  end

  it "should get index with view_mode group and correct sorting" do
    grupo = grupos(:one)
    
    # Limpa os jogos do grupo para fazer um teste isolado
    Jogo.where(grupo_id: grupo.id).destroy_all

    # Cria jogo 1: finalizado, mais antigo (2026-06-20)
    jogo_finalizado_antigo = Jogo.create!(
      mandante: selecoes(:one),
      visitante: selecoes(:two),
      gols_mandante: 2,
      gols_visitante: 1,
      data: Time.zone.parse("2026-06-20 15:00:00"),
      tipo: :grupo,
      grupo: grupo,
      uuid: SecureRandom.uuid,
      definir: false,
      status: :finalizado
    )

    # Cria jogo 2: finalizado, mais recente (2026-06-22)
    jogo_finalizado_recente = Jogo.create!(
      mandante: selecoes(:one),
      visitante: selecoes(:two),
      gols_mandante: 0,
      gols_visitante: 0,
      data: Time.zone.parse("2026-06-22 18:00:00"),
      tipo: :grupo,
      grupo: grupo,
      uuid: SecureRandom.uuid,
      definir: false,
      status: :finalizado
    )

    # Cria jogo 3: programado (ainda vai acontecer), mais recente que os outros (2026-06-25)
    jogo_programado = Jogo.create!(
      mandante: selecoes(:one),
      visitante: selecoes(:two),
      gols_mandante: 0,
      gols_visitante: 0,
      data: Time.zone.parse("2026-06-25 20:00:00"),
      tipo: :grupo,
      grupo: grupo,
      uuid: SecureRandom.uuid,
      definir: false,
      status: :programado
    )

    get jogos_path, params: { tipo: 'grupo', view_mode: 'grupo', grupo: grupo.uuid }
    expect(response).to have_http_status(:success)

    # Chamamos o service diretamente para validar a ordenação
    jogos_list = Jogos::List.new(params: { tipo: 'grupo', view_mode: 'grupo', grupo: grupo.uuid }).call.to_a
    
    # A ordenação correta deve colocar primeiro os que ainda vão acontecer (jogo_programado)
    # e depois os finalizados, ordenados cronologicamente do mais antigo para o mais recente
    # (jogo_finalizado_antigo primeiro, jogo_finalizado_recente depois)
    expect(jogos_list.size).to eq(3)
    expect(jogos_list[0].id).to eq(jogo_programado.id)
    expect(jogos_list[1].id).to eq(jogo_finalizado_antigo.id)
    expect(jogos_list[2].id).to eq(jogo_finalizado_recente.id)
  end

  it "should get index with view_mode list and fetch all games of all phases" do
    grupo_one = grupos(:one)
    grupo_two = grupos(:two)

    # Garante que existem jogos em grupos diferentes
    Jogo.create!(
      mandante: selecoes(:one),
      visitante: selecoes(:two),
      data: Time.current,
      tipo: :grupo,
      grupo: grupo_one,
      uuid: SecureRandom.uuid,
      definir: false,
      status: :programado
    )

    Jogo.create!(
      mandante: selecoes(:one),
      visitante: selecoes(:two),
      data: Time.current + 1.day,
      tipo: :grupo,
      grupo: grupo_two,
      uuid: SecureRandom.uuid,
      definir: false,
      status: :programado
    )

    get jogos_path, params: { view_mode: 'lista' }
    expect(response).to have_http_status(:success)

    # Chamamos o service diretamente para validar a listagem geral de todas as fases (tipo: nil)
    jogos_list = Jogos::List.new(params: { tipo: nil, view_mode: 'lista' }).call.to_a
    
    # No modo por lista, deve trazer todos os jogos do campeonato, sem limitar por grupo ou tipo individual
    expect(jogos_list.size).to be >= 2
  end
end
