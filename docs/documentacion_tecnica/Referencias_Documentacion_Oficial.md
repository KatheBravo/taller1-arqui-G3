# Referencias a la Documentación Oficial por Tecnología
## DecisionRoom G3 - Sistema de Votación en Tiempo Real

Este documento recopila los enlaces directos a la documentación oficial, especificaciones técnicas y estándares de la industria empleados en el diseño e implementación del proyecto, clasificados por tecnología y caso de uso específico.

---

## 1. Estilo Arquitectónico: Clean Architecture

### Documentación y Fuentes Primarias:
*   **The Clean Architecture (Blog Original - Robert C. Martin "Uncle Bob", 2012):**  
    https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html  
    *Aspectos aplicados:* La Regla de Dependencia concéntrica, el aislamiento de entidades respecto a frameworks y la definición de casos de uso como objetos interactores.
*   **Hexagonal Architecture / Puertos y Adaptadores (Alistair Cockburn, 2005):**  
    https://alistair.cockburn.us/hexagonal-architecture/  
    *Aspectos aplicados:* Separación entre el interior de la aplicación (dominio y casos de uso) y los adaptadores externos (puertos de entrada como WebSockets y puertos de salida como Redis).
*   **Libro de Referencia:** *Clean Architecture: A Craftsman's Guide to Software Structure and Design* (Robert C. Martin, Prentice Hall, 2017).

---

## 2. Frontend: Electron + Python (Eel)

### Documentación Oficial de Eel:
*   **Repositorio Oficial y Especificación de API (GitHub - python-eel/Eel):**  
    https://github.com/python-eel/Eel  
    *Aspectos aplicados:*
    *   Inicialización del directorio web estático: `eel.init('web')`.
    *   Exportación de funciones Python a JavaScript mediante el decorador `@eel.expose`.
    *   Invocación de funciones de JavaScript desde Python (ej. `eel.update_results(...)()`).
    *   Configuración del modo de ventana Chromium y fallback de navegadores (`mode="chrome"`, `mode="edge"`).
*   **Integración de Eel con Electron (Documentación de despliegue):**  
    https://github.com/python-eel/Eel#electron-and-native-apps  
    *Aspectos aplicados:* Empaquetado de la ventana de renderizado de Chromium con el runtime de Python.
*   **Compilación con PyInstaller:**  
    https://pyinstaller.org/en/stable/  
    *Aspectos aplicados:* Generación del ejecutable único independiente mediante `python -m eel main.py web --onefile --noconsole`.

### Arquitectura de Electron / Chromium:
*   **Procesos de Electron (Main Process vs. Renderer Process):**  
    https://www.electronjs.org/docs/latest/tutorial/process-model  
    *Aspectos aplicados:* Justificación arquitectónica del desacoplamiento entre el proceso host del sistema operativo (Python) y el motor de dibujo web (Chromium/HTML5/CSS).

---

## 3. Backend: Ruby on Rails (Modo API sin ActiveRecord)

### Guías Oficiales de Ruby on Rails (Rails Guides v7.1):
*   **Uso de Rails para Aplicaciones Exclusivas de API (Rails API-only):**  
    https://guides.rubyonrails.org/api_app.html  
    *Aspectos aplicados:* Generación con `--api`, eliminación del middleware innecesario para renderizado tradicional de plantillas y configuración ligera de controladores.
*   **Configuración de Frameworks en Rails (Omitir ActiveRecord):**  
    https://guides.rubyonrails.org/configuring.html#configuring-a-framework  
    *Aspectos aplicados:* Exclusión intencionada de `active_record/railtie` en `config/application.rb` y personalización de las rutas de autocarga (`config.autoload_paths`) para soportar `app/core` y `app/infrastructure`.
*   **ActionCable Overview (WebSockets en Rails):**  
    https://guides.rubyonrails.org/action_cable_overview.html  
    *Aspectos aplicados:* Creación de canales (`ApplicationCable::Channel`), flujos de transmisión con `stream_from`, recepción de comandos de clientes y métodos de broadcast general (`ActionCable.server.broadcast`).
*   **Servidor Web Multihilo Puma:**  
    https://puma.io/puma/  
    *Aspectos aplicados:* Configuración de concurrencia y grupos de hilos en `config/puma.rb` para soportar múltiples conexiones persistentes simultáneas de WebSockets.

---

## 4. Persistencia: Redis (In-Memory Engine y Pub/Sub)

### Documentación Oficial de Comandos de Redis:
*   **Comandos de Hashes (Estructuras Clave-Valor):**
    *   `HSET`: https://redis.io/commands/hset/ (Persistencia de metadatos de encuestas y votos).
    *   `HGETALL`: https://redis.io/commands/hgetall/ (Lectura completa de estados).
    *   `HINCRBY`: https://redis.io/commands/hincrby/ (Incremento atómico de votos con complejidad O(1)).
*   **Comandos de Sets (Conjuntos Únicos):**
    *   `SADD`: https://redis.io/commands/sadd/ (Validación atómica de unicidad para evitar votos duplicados).
    *   `SMEMBERS`: https://redis.io/commands/smembers/ (Consulta de votantes participantes).
    *   `SISMEMBER`: https://redis.io/commands/sismember/ (Verificación de existencia en tiempo O(1)).
*   **Mecanismo de Publicación y Suscripción (Pub/Sub):**  
    https://redis.io/docs/interact/pubsub/  
    *Aspectos aplicados:* Canal de mensajería interno que conecta a los workers de ActionCable para distribuir los eventos de voto.
*   **Persistencia en Disco (Append-Only File - AOF):**  
    https://redis.io/docs/management/persistence/  
    *Aspectos aplicados:* Configuración del comando `--appendonly yes` en Docker Compose para garantizar durabilidad de datos.
*   **Cliente Oficial de Ruby para Redis (Gema `redis-rb`):**  
    https://github.com/redis/redis-rb  
    *Aspectos aplicados:* Inicialización del pool de conexión global `REDIS_CLIENT` con reintentos automáticos y timeouts.

---

## 5. Protocolo de Integración: WebSockets y ActionCable Subprotocol

### Estándar del Protocolo WebSockets:
*   **RFC 6455 - The WebSocket Protocol (IETF Standard):**  
    https://datatracker.ietf.org/doc/html/rfc6455  
    *Aspectos aplicados:* Conmutación de protocolo HTTP a TCP continuo mediante el apretón de manos inicial (*Handshake*), comunicación bidireccional de baja latencia sin cabeceras redundantes.

### Subprotocolo de ActionCable (Rails WebSocket Protocol):
*   **Especificación del Protocolo de Red de ActionCable:**  
    https://github.com/rails/rails/tree/main/actioncable  
    *Aspectos aplicados en Python:*
    *   Recepción del mensaje inicial de bienvenida: `{"type":"welcome"}`.
    *   Trama de suscripción JSON: `{"command":"subscribe","identifier":"{\"channel\":\"VotingChannel\"}"}`.
    *   Confirmación de suscripción: `{"type":"confirm_subscription"}`.
    *   Filtrado de latidos de salud periódicos: `{"type":"ping"}`.
*   **Librería Python `websockets`:**  
    https://websockets.readthedocs.io/en/stable/  
    *Aspectos aplicados:* Conexión cliente asíncrona mediante `websockets.connect()` operando en un hilo secundario coordinado con la interfaz gráfica.

---

## 6. Infraestructura: Contenedores con Docker y Podman

### Documentación de Docker Engine y Compose:
*   **Especificación de Dockerfile:**  
    https://docs.docker.com/reference/dockerfile/  
    *Aspectos aplicados:* Imagen base minimalista `ruby:3.2-alpine`, dependencias de compilación nativa con `apk add build-base`, y definición de puntos de entrada `CMD`.
*   **Especificación de Docker Compose (Compose File v3.8):**  
    https://docs.docker.com/compose/compose-file/03-compose-file/  
    *Aspectos aplicados:*
    *   Mapeo de puertos (`3000:3000` y `6379:6379`).
    *   Volumen con nombre (`redis_data`) para la persistencia física en el host.
    *   Red virtual interna tipo bridge (`decisionroom_network`) para comunicación aislada sin exponer Redis a la red pública.
    *   Control de dependencias de arranque (`depends_on: redis`).
