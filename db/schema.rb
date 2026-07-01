# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_01_130142) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "assinaturas", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.integer "plano", null: false
    t.boolean "ativa", null: false
    t.datetime "data_expiracao"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "uuid", null: false
  end

  create_table "cobrancas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plano", null: false
    t.integer "valor", null: false
    t.integer "status", null: false
    t.string "gateway", null: false
    t.string "gateway_cobranca_id"
    t.string "gateway_checkout_url"
    t.string "payment_method", null: false
    t.datetime "expires_at"
    t.datetime "paid_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "pix_qr_code"
    t.text "pix_qr_code_base64"
    t.string "gateway_status"
    t.uuid "uuid", null: false
  end

  create_table "conquistas", force: :cascade do |t|
    t.string "nome", null: false
    t.string "descricao", null: false
    t.string "slug", null: false
    t.string "icon", null: false
    t.string "cor", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_conquistas_on_slug", unique: true
    t.index ["uuid"], name: "index_conquistas_on_uuid", unique: true
  end

  create_table "grupos", force: :cascade do |t|
    t.string "nome"
    t.integer "rodadas"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "uuid", null: false
  end

  create_table "informacao_jogos", force: :cascade do |t|
    t.bigint "jogo_id", null: false
    t.json "dados"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jogo_id"], name: "index_informacao_jogos_on_jogo_id"
  end

  create_table "jogadores", force: :cascade do |t|
    t.bigint "selecao_id", null: false
    t.string "nome", null: false
    t.integer "numero"
    t.string "posicao"
    t.date "data_nascimento"
    t.integer "idade_torneio"
    t.string "clube"
    t.string "clube_pais"
    t.boolean "capitao", default: false, null: false
    t.integer "gols", default: 0, null: false
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assistencias", default: 0, null: false
    t.index ["selecao_id"], name: "index_jogadores_on_selecao_id"
  end

  create_table "jogos", force: :cascade do |t|
    t.bigint "mandante_id"
    t.bigint "visitante_id"
    t.integer "gols_mandante"
    t.integer "gols_visitante"
    t.datetime "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "tipo", null: false
    t.bigint "grupo_id"
    t.boolean "definir", null: false
    t.string "estadio"
    t.string "nome_provisorio_mandante"
    t.string "nome_provisorio_visitante"
    t.integer "status"
    t.uuid "uuid", null: false
    t.integer "prob_mandante"
    t.integer "prob_empate"
    t.integer "prob_visitante"
    t.bigint "vencedor_penaltis_id"
    t.integer "gols_penaltis_mandante"
    t.integer "gols_penaltis_visitante"
    t.string "sequencia_penaltis_mandante"
    t.string "sequencia_penaltis_visitante"
    t.index ["vencedor_penaltis_id"], name: "index_jogos_on_vencedor_penaltis_id"
  end

  create_table "liga_membros", force: :cascade do |t|
    t.bigint "liga_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status"
    t.integer "role"
    t.bigint "invited_by_id"
    t.uuid "uuid", null: false
  end

  create_table "ligas", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "nome"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "membros", null: false
    t.string "invite_token"
    t.boolean "publica", null: false
    t.boolean "entrada_livre", null: false
    t.uuid "uuid", null: false
    t.boolean "pontuacao_zerada", default: false, null: false
  end

  create_table "metricas_acessos", force: :cascade do |t|
    t.string "key"
    t.string "nome"
    t.integer "acessos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_metricas_acessos_on_key", unique: true
  end

  create_table "notificacoes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "tipo"
    t.integer "sender_id"
    t.text "texto"
    t.integer "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "liga_id"
    t.boolean "answered"
    t.uuid "uuid", null: false
    t.string "link"
  end

  create_table "pagamentos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_customer_id"
    t.string "stripe_invoice_id"
    t.integer "valor", null: false
    t.integer "status", null: false
    t.string "plano"
    t.datetime "pago_em"
    t.jsonb "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "cobranca_id", null: false
    t.string "mercado_pago_payment_id"
    t.uuid "uuid", null: false
  end

  create_table "palpites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "jogo_id", null: false
    t.integer "gols_casa", null: false
    t.integer "gols_fora", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "uuid", null: false
    t.bigint "vencedor_penaltis_id"
    t.integer "gols_penaltis_casa"
    t.integer "gols_penaltis_fora"
    t.index ["vencedor_penaltis_id"], name: "index_palpites_on_vencedor_penaltis_id"
  end

  create_table "selecoes", force: :cascade do |t|
    t.string "nome"
    t.integer "pontos"
    t.integer "qtd_jogos"
    t.integer "vitorias"
    t.integer "derrotas"
    t.integer "empates"
    t.string "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "grupo_id", null: false
    t.bigint "qtd_torcedores"
    t.bigint "gols"
    t.bigint "gols_sofridos"
    t.uuid "uuid", null: false
    t.boolean "desclassificada", default: false, null: false
  end

  create_table "user_conquistas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conquista_id", null: false
    t.bigint "jogo_id"
    t.boolean "destacada", default: false, null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visualizada", default: false, null: false
    t.index ["conquista_id"], name: "index_user_conquistas_on_conquista_id"
    t.index ["jogo_id"], name: "index_user_conquistas_on_jogo_id"
    t.index ["user_id", "conquista_id"], name: "index_user_conquistas_on_user_id_and_conquista_id", unique: true
    t.index ["user_id"], name: "index_user_conquistas_on_user_id"
    t.index ["uuid"], name: "index_user_conquistas_on_uuid", unique: true
  end

  create_table "user_points", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "jogo_id", null: false
    t.integer "pontos"
    t.string "motivo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "uuid", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", null: false
    t.string "logo_selecao"
    t.integer "pontos"
    t.integer "tipo"
    t.bigint "selecao_id"
    t.string "password_recovery_token"
    t.datetime "password_recovery_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "terms_accepted_at"
    t.string "provider"
    t.string "uid"
    t.integer "referred_by_id"
    t.integer "referrals_count"
    t.datetime "referral_counted_at"
    t.uuid "uuid", null: false
    t.boolean "esconder_odds", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "last_seen_at"
    t.datetime "penaltis_scoring_notice_seen_at"
  end

  add_foreign_key "informacao_jogos", "jogos"
  add_foreign_key "jogadores", "selecoes"
  add_foreign_key "jogos", "selecoes", column: "vencedor_penaltis_id"
  add_foreign_key "palpites", "selecoes", column: "vencedor_penaltis_id"
  add_foreign_key "user_conquistas", "conquistas"
  add_foreign_key "user_conquistas", "jogos"
  add_foreign_key "user_conquistas", "users"
end
