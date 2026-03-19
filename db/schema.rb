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

ActiveRecord::Schema[7.1].define(version: 2026_03_19_015834) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "grupos", force: :cascade do |t|
    t.string "nome"
    t.integer "rodadas", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jogos", force: :cascade do |t|
    t.bigint "mandante_id"
    t.bigint "visitante_id"
    t.integer "gols_mandante", default: 0
    t.integer "gols_visitante", default: 0
    t.datetime "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tipo", default: 0, null: false
    t.bigint "grupo_id"
    t.boolean "definir", default: false, null: false
    t.string "estadio"
    t.string "nome_provisorio_mandante"
    t.string "nome_provisorio_visitante"
    t.integer "status", default: 0
    t.index ["grupo_id"], name: "index_jogos_on_grupo_id"
    t.index ["mandante_id"], name: "index_jogos_on_mandante_id"
    t.index ["visitante_id"], name: "index_jogos_on_visitante_id"
  end

  create_table "liga_membros", force: :cascade do |t|
    t.bigint "liga_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.integer "role"
    t.bigint "invited_by_id"
    t.index ["liga_id", "user_id"], name: "index_liga_membros_on_liga_id_and_user_id", unique: true
    t.index ["liga_id"], name: "index_liga_membros_on_liga_id"
    t.index ["user_id"], name: "index_liga_membros_on_user_id"
  end

  create_table "ligas", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "membros", default: 0, null: false
    t.index ["owner_id"], name: "index_ligas_on_owner_id"
  end

  create_table "notificacoes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "tipo"
    t.integer "sender_id"
    t.text "texto"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "liga_id"
    t.index ["user_id"], name: "index_notificacoes_on_user_id"
  end

  create_table "palpites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "jogo_id", null: false
    t.integer "gols_casa", null: false
    t.integer "gols_fora", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jogo_id"], name: "index_palpites_on_jogo_id"
    t.index ["user_id", "jogo_id"], name: "index_palpites_on_user_id_and_jogo_id", unique: true
    t.index ["user_id"], name: "index_palpites_on_user_id"
  end

  create_table "selecoes", force: :cascade do |t|
    t.string "nome"
    t.integer "pontos", default: 0
    t.integer "qtd_jogos", default: 0
    t.integer "vitorias", default: 0
    t.integer "derrotas", default: 0
    t.integer "empates", default: 0
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "grupo_id", null: false
    t.bigint "qtd_torcedores", default: 0
    t.bigint "gols", default: 0
    t.bigint "gols_sofridos", default: 0
    t.index ["grupo_id"], name: "index_selecoes_on_grupo_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "logo_selecao"
    t.integer "pontos"
    t.integer "tipo", default: 0
    t.bigint "selecao_id"
    t.string "password_recovery_token"
    t.datetime "password_recovery_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["selecao_id"], name: "index_users_on_selecao_id"
  end

  add_foreign_key "jogos", "grupos"
  add_foreign_key "jogos", "selecoes", column: "mandante_id"
  add_foreign_key "jogos", "selecoes", column: "visitante_id"
  add_foreign_key "liga_membros", "ligas"
  add_foreign_key "liga_membros", "users"
  add_foreign_key "ligas", "users", column: "owner_id"
  add_foreign_key "notificacoes", "users"
  add_foreign_key "palpites", "jogos"
  add_foreign_key "palpites", "users"
  add_foreign_key "selecoes", "grupos"
  add_foreign_key "users", "selecoes"
end
