# Número de threads por worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Ambiente do Rails - Mudei de "production" para "development" como padrão para facilitar sua vida local
environment ENV.fetch("RAILS_ENV") { "development" }

# Número de workers (processos)
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Carrega a aplicação antes de criar workers
preload_app!

# Lógica inteligente para o Socket ou Porta
if ENV.fetch("RAILS_ENV", "development") == "production"
  bind "unix:///home/upontes/orangScore/tmp/sockets/puma.sock"
  # No servidor, usamos caminhos absolutos para o systemd não se perder
  pidfile "/home/upontes/orangScore/tmp/pids/puma.pid"
  state_path "/home/upontes/orangScore/tmp/pids/puma.state"
else
  port ENV.fetch("PORT") { 3000 }
  # Localmente, usamos caminhos relativos à pasta do projeto
  pidfile "tmp/pids/server.pid"
end

# Permite reiniciar com `rails restart`
plugin :tmp_restart