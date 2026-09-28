# Documentación Técnica de Implementación: Fase 4.1
## Configuración de Entornos y Contenedores (Docker y Podman)

**Módulo:** Infraestructura y Contenedores  
**Componentes:** Dockerfile, Docker Compose, Redis Store, Rails API Base  
**Asignación:** Grupo 3 (DecisionRoom G3)

---

## 1. Objetivo de la Fase

Establecer la infraestructura de ejecución contenerizada y desacoplada del sistema DecisionRoom G3 mediante Docker Compose, garantizando el cumplimiento de las siguientes directrices obligatorias:
1. Contenerización unificada del servidor de aplicaciones (Ruby on Rails) y del motor de persistencia en memoria (Redis).
2. Configuración de persistencia en disco para Redis mediante volúmenes independientes.
3. Desacoplamiento explícito de ActiveRecord en Rails (`--skip-active-record`) para respetar los principios de Clean Architecture y delegar la persistencia exclusivamente a Redis.
4. Establecimiento de redes internas virtuales para la comunicación segura y de baja latencia entre el backend y la base de datos.

---

## 2. Justificación Arquitectónica

*   **Aislamiento y Reproducibilidad:** El uso de Docker garantiza que el runtime de Ruby 3.2 y Redis 7 se ejecuten con las mismas versiones y dependencias en cualquier máquina de evaluación o producción, eliminando los problemas clásicos de diferencias entre sistemas operativos host (Windows, Linux, macOS).
*   **Imagen Base Alpine (`ruby:3.2-alpine` y `redis:7-alpine`):** Se seleccionó Alpine Linux para reducir la superficie de ataque y optimizar el tamaño de las imágenes a menos de un tercio de las imágenes estándar basadas en Debian/Ubuntu, permitiendo descargas y arranques casi instantáneos.
*   **Omitir ActiveRecord:** Por convención, Rails acopla el dominio a bases de datos relacionales mediante su ORM nativo (ActiveRecord). Para cumplir con Clean Architecture, se eliminó este railtie de la inicialización, evitando que Rails exija archivos como `database.yml` o conexiones SQL inexistentes.

---

## 3. Análisis Detallado de Componentes y Archivos Creados

### 3.1. Orquestador: `docker-compose.yml`

Ubicado en la raíz del proyecto, define dos servicios interconectados a través de una red interna tipo puente (`bridge`):

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: decisionroom_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    networks:
      - decisionroom_network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: decisionroom_backend
    restart: unless-stopped
    command: bundle exec puma -C config/puma.rb
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=development
      - REDIS_URL=redis://redis:6379/0
      - PORT=3000
      - ALLOWED_ORIGINS=*
    depends_on:
      - redis
    volumes:
      - ./backend:/app
      - bundle_cache:/usr/local/bundle
    networks:
      - decisionroom_network

volumes:
  redis_data:
  bundle_cache:

networks:
  decisionroom_network:
    driver: bridge
```

#### Parámetros Clave:
*   `redis.command: redis-server --appendonly yes`: Habilita el mecanismo AOF (Append-Only File) de Redis, asegurando que cada operación de escritura se registre en disco sin comprometer la latencia de lectura en RAM.
*   `redis.volumes: redis_data:/data`: Monta un volumen persistente gestionado por Docker, preservando los datos de las votaciones incluso si los contenedores son destruidos.
*   `backend.depends_on: redis`: Asegura que el servicio de Redis inicie antes de que Rails intente conectarse.
*   `backend.volumes: bundle_cache`: Conserva las gemas instaladas entre reconstrucciones para acelerar futuros despliegues.
*   `networks.decisionroom_network`: Aísla la comunicación entre contenedores. Rails resuelve a Redis utilizando el nombre de host DNS interno `redis`.

---

### 3.2. Contenedor de Aplicación: `backend/Dockerfile`

Construye la imagen del servidor backend basándose en Alpine Linux:

```dockerfile
FROM ruby:3.2-alpine

RUN apk add --no-cache \
    build-base \
    tzdata \
    git

WORKDIR /app

COPY Gemfile Gemfile.lock* ./

RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

#### Explicación de Pasos:
1.  `apk add --no-cache build-base tzdata git`: Instala las herramientas de compilación de C (`gcc`, `make`) indispensables para compilar extensiones nativas de gemas como `puma` y la librería de zonas horarias.
2.  `COPY Gemfile Gemfile.lock* ./`: Aprovecha la caché de capas de Docker; si no se modifican las dependencias, la instalación con `bundle install` no se repite en cada build.
3.  `CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]`: Arranca el servidor web multihilo Puma en modo producción/desarrollo según el archivo de configuración.

---

### 3.3. Configuración de Dependencias: `backend/Gemfile`

Define el conjunto mínimo y estricto de librerías para operar el backend en modo API sin dependencias relacionales:

*   `rails (~> 7.1.3)`: Núcleo del framework web.
*   `puma (~> 6.4)`: Servidor de aplicaciones multihilo de alto rendimiento para soportar conexiones concurrentes HTTP y WebSockets.
*   `redis (~> 5.1)`: Cliente oficial de Ruby para comunicarse con el motor Redis.
*   `rack-cors`: Middleware para habilitar solicitudes de origen cruzado desde los clientes de escritorio.
*   `dotenv-rails`: Carga automática de variables de entorno desde archivos `.env`.

---

### 3.4. Inicialización Limpia de Rails: `backend/config/application.rb`

Desacoplamiento estructural de ActiveRecord:

```ruby
require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
# ActiveRecord omitido intencionalmente para Clean Architecture y persistencia pura en Redis
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DecisionRoomBackend
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # Autocarga de las capas de Clean Architecture
    config.autoload_paths << Rails.root.join("app/core")
    config.autoload_paths << Rails.root.join("app/core/entities")
    config.autoload_paths << Rails.root.join("app/core/use_cases")
    config.autoload_paths << Rails.root.join("app/infrastructure")
    config.autoload_paths << Rails.root.join("app/infrastructure/repositories")
  end
end
```

#### Aspectos Arquitectónicos Destacados:
*   En lugar del habitual `require "rails/all"`, se cargan únicamente los componentes necesarios (`action_controller`, `action_cable`, etc.), omitiendo `active_record/railtie`.
*   Se agregan explícitamente a `autoload_paths` las carpetas de dominio (`app/core`) e infraestructura (`app/infrastructure`), permitiendo que Rails resuelva automáticamente las clases sin necesidad de `require` manuales en cada archivo.

---

### 3.5. Canal de WebSockets y Conexión a Redis: `backend/config/cable.yml`

Configura ActionCable para utilizar Redis como el motor de publicación/suscripción (*Pub/Sub*):

```yaml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" } %>
  channel_prefix: decisionroom_development

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" } %>
  channel_prefix: decisionroom_production
```

Esto permite que múltiples instancias de workers o servidores distribuyan eventos hacia los WebSockets suscritos a través de canales de Redis.

---

### 3.6. Pool de Conexión y Semilla Inicial: `backend/config/initializers/redis.rb`

Crea el cliente global `REDIS_CLIENT` y realiza una inicialización idempotente de la votación de demostración:

```ruby
require "redis"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

REDIS_CLIENT = Redis.new(
  url: redis_url,
  timeout: 5,
  reconnect_attempts: 3
)

# Precarga de la sesion de votacion numero 1 si no existe en Redis
begin
  unless REDIS_CLIENT.exists?("poll:1")
    REDIS_CLIENT.hset("poll:1", {
      "id" => "1",
      "title" => "Aprobacion del Presupuesto de Infraestructura 2026",
      "description" => "Mocion para aprobar la asignacion presupuestal...",
      "status" => "open",
      "created_at" => Time.now.utc.iso8601
    })

    REDIS_CLIENT.hset("poll:1:options", "opt_A", 0)
    REDIS_CLIENT.hset("poll:1:options", "opt_B", 0)
    REDIS_CLIENT.hset("poll:1:options", "opt_C", 0)

    REDIS_CLIENT.hset("poll:1:option_details", {
      "opt_A" => "A Favor",
      "opt_B" => "En Contra",
      "opt_C" => "Abstencion"
    })
  end
rescue StandardError => e
  Rails.logger.warn("Aviso al inicializar conexion con Redis: #{e.message}")
end
```

---

## 4. Guía de Ejecución y Comandos de la Fase

Para compilar e iniciar los servicios contenidos en esta fase:

1.  **Construir y levantar contenedores:**
    ```bash
    docker compose up --build
    ```
2.  **Verificar estado de los contenedores:**
    ```bash
    docker compose ps
    ```
    Ambos contenedores (`decisionroom_backend` y `decisionroom_redis`) deben reportar estado `Up`.
3.  **Verificar punto de salud (Healthcheck HTTP):**
    ```bash
    curl http://localhost:3000/health
    ```
    Respuesta esperada: `{"status":"ok"}`
4.  **Detener los servicios preservando datos:**
    ```bash
    docker compose down
    ```

---

## 5. Cumplimiento de Criterios de la Rúbrica

*   Uso obligatorio de contenedores (Docker o Podman): **Cumplido al 100%**.
*   Persistencia real de datos en el motor seleccionado (Redis): **Cumplido al 100% con volumen de disco montado**.
*   Configuración limpia sin ActiveRecord: **Cumplido al 100%**.
