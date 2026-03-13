# Número de threads por worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Ambiente do Rails
environment ENV.fetch("RAILS_ENV") { "production" }

# Número de workers (processos)
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Carrega a aplicação antes de criar workers
preload_app!

# Socket usado pelo Nginx para conversar com o Puma
bind "unix:///home/upontes/orangScore/tmp/sockets/puma.sock"

# Arquivo que guarda o PID do processo
pidfile "/home/upontes/orangScore/tmp/pids/puma.pid"

# Arquivo de estado do Puma
state_path "/home/upontes/orangScore/tmp/pids/puma.state"

# Permite reiniciar com `rails restart`
plugin :tmp_restart