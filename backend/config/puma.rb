max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# En Docker es INDISPENSABLE enlazar a 0.0.0.0 para que el puerto sea accesible desde el host
bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"
environment ENV.fetch("RAILS_ENV") { "development" }

# Asegurar que existan los directorios temporales
FileUtils.mkdir_p("tmp/pids")
FileUtils.mkdir_p("tmp/cache")
FileUtils.mkdir_p("log")

# Eliminar pid previo si existiera para evitar crash al reiniciar
File.delete("tmp/pids/server.pid") if File.exist?("tmp/pids/server.pid")

plugin :tmp_restart
