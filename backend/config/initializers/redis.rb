require "redis"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

REDIS_CLIENT = Redis.new(
  url: redis_url,
  timeout: 5,
  reconnect_attempts: 3
)

# Inicializar datos por defecto si la base de datos de Redis esta vacia
begin
  unless REDIS_CLIENT.exists?("poll:1")
    # Votacion inicial de prueba
    REDIS_CLIENT.hset("poll:1", {
      "id" => "1",
      "title" => "Aprobacion del Presupuesto de Infraestructura 2026",
      "description" => "Mocion para aprobar la asignacion presupuestal destinada a la renovacion de servidores y arquitectura de tiempo real.",
      "status" => "open",
      "created_at" => Time.now.utc.iso8601
    })

    # Opciones de la votacion
    REDIS_CLIENT.hset("poll:1:options", "opt_A", 0) # A Favor
    REDIS_CLIENT.hset("poll:1:options", "opt_B", 0) # En Contra
    REDIS_CLIENT.hset("poll:1:options", "opt_C", 0) # Abstencion

    # Descripciones textuales de las opciones
    REDIS_CLIENT.hset("poll:1:option_details", {
      "opt_A" => "A Favor",
      "opt_B" => "En Contra",
      "opt_C" => "Abstencion"
    })
  end
rescue StandardError => e
  Rails.logger.warn("Aviso al inicializar conexion con Redis: #{e.message}")
end
