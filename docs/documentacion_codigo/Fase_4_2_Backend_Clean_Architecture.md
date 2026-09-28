# Documentación Técnica de Implementación: Fase 4.2
## Backend con Clean Architecture en Ruby on Rails

**Módulo:** Backend y Lógica de Negocio  
**Patrón Arquitectónico:** Clean Architecture (Puertos y Adaptadores / Arquitectura Hexagonal)  
**Asignación:** Grupo 3 (DecisionRoom G3)

---

## 1. Objetivo de la Fase

Implementar el núcleo funcional del sistema DecisionRoom G3 aplicando estrictamente los principios de **Clean Architecture**, asegurando que:
1. Las entidades de negocio sean objetos puros de Ruby (POROs), completamente independientes de frameworks web o motores de bases de datos.
2. Los casos de uso orquesten las reglas de negocio sin acoplarse al protocolo de red (WebSockets/HTTP) ni a la tecnología concreta de persistencia.
3. La persistencia en Redis se implemente a través del Patrón Repositorio, aprovechando operaciones atómicas en memoria para garantizar rendimiento y consistencia.
4. El mecanismo de entrega mediante WebSockets (ActionCable) actúe únicamente como un adaptador de entrada que desempaqueta solicitudes y distribuye eventos reactivos.

---

## 2. Justificación Arquitectónica: Clean Architecture en Ruby

En un proyecto convencional de Ruby on Rails, el patrón dominante es MVC acoplado mediante ActiveRecord. Sin embargo, en Clean Architecture:
*   **Regla de Dependencia:** Las dependencias del código fuente apuntan exclusivamente hacia adentro. Las entidades desconocen los casos de uso; los casos de uso desconocen los controladores y la base de datos; la infraestructura (Redis) y los mecanismos de entrega (ActionCable) dependen de contratos abstractos del dominio.
*   **PORO vs ActiveRecord Model:** Un modelo ActiveRecord mezcla la definición del esquema de la base de datos, las consultas SQL, las validaciones y los callbacks en una sola clase pesada. En cambio, nuestras entidades (`Poll`, `Option`, `Vote`) son objetos planos de Ruby que solo contienen datos de negocio y métodos de consulta semánticos (`open?`, `closed?`).
*   **Testabilidad Absoluta:** Al desacoplar los casos de uso (`RegisterVote`) mediante inyección de dependencias (`initialize(repository:, broadcaster:)`), es posible probar el 100% de la lógica de negocio mediante pruebas unitarias inyectando repositorios simulados (*Mocks*) en memoria sin requerir Redis ni servidores web activos.

---

## 3. Análisis Detallado de Capas y Archivos Creados

```text
backend/app/
├── core/                                # NÚCLEO INDEPENDIENTE (Clean Domain)
│   ├── errors.rb                        # Jerarquía de excepciones de negocio
│   ├── entities/                        # Modelos puros sin dependencias
│   │   ├── poll.rb
│   │   ├── option.rb
│   │   └── vote.rb
│   └── use_cases/                       # Casos de uso de la aplicación
│       ├── register_vote.rb
│       └── get_poll_results.rb
├── infrastructure/                      # ADAPTADORES DE SALIDA (Infraestructura)
│   └── repositories/
│       └── redis_vote_repository.rb     # Persistencia atómica en Redis
├── channels/                            # ADAPTADORES DE ENTRADA (WebSockets)
│   └── voting_channel.rb
└── controllers/                         # ADAPTADORES DE ENTRADA (REST API)
    ├── application_controller.rb
    └── polls_controller.rb
```

---

### 3.1. Capa de Dominio: Entidades de Negocio Puras

Ubicadas en `app/core/entities/`. No heredan de ninguna clase base del framework.

#### A. Entidad `Poll` (`app/core/entities/poll.rb`)
Modela la moción o asunto sometido a votación:
*   `id`: Identificador único de la votación.
*   `title`: Título formal de la propuesta.
*   `description`: Explicación detallada del asunto en debate.
*   `status`: Estado de la sesión (`open` o `closed`).
*   `created_at`: Marca de tiempo ISO-8601.
*   *Métodos de Dominio:* `open?` (verifica si se admiten votos) y `closed?`.

#### B. Entidad `Option` (`app/core/entities/option.rb`)
Modela cada una de las alternativas disponibles dentro de una votación:
*   `id`: Identificador de la opción (ej. `opt_A`, `opt_B`, `opt_C`).
*   `poll_id`: Votación a la que pertenece (relación 1 a muchos).
*   `text`: Texto descriptivo (ej. "A Favor", "En Contra", "Abstención").
*   `current_votes`: Conteo numérico de votos acumulados en memoria.

#### C. Entidad `Vote` (`app/core/entities/vote.rb`)
Modela la acción individual de emisión de voto:
*   `id`: UUID del voto registrado.
*   `poll_id`: Identificador de la moción votada.
*   `option_id`: Opción elegida.
*   `voter_fingerprint`: Hash o identificador anónimo de la terminal del votante.
*   `cast_at`: Momento exacto de emisión para propósitos de auditoría.

---

### 3.2. Errores de Dominio Específicos (`app/core/errors.rb`)

Define una jerarquía de excepciones que expresa con claridad semántica los fallos de negocio:

```ruby
module Core
  module Errors
    class DomainError < StandardError; end
    class PollNotFoundError < DomainError; end
    class PollClosedError < DomainError; end
    class InvalidOptionError < DomainError; end
    class DuplicateVoteError < DomainError; end
  end
end
```

Esto permite capturar y clasificar los errores en los adaptadores sin depender de excepciones genéricas de base de datos.

---

### 3.3. Capa de Infraestructura: Adaptador sobre Redis (`app/infrastructure/repositories/redis_vote_repository.rb`)

Implementa el acceso a datos sobre Redis utilizando estructuras nativas en memoria diseñadas para alto rendimiento y concurrencia atómica:

#### Operaciones Atómicas Clave:
1.  **Control de Unicidad de Voto con `SADD`:**
    ```ruby
    is_new_voter = @redis.sadd("poll:#{poll_id}:voters", voter_fingerprint)
    if is_new_voter == 0
      raise Core::Errors::DuplicateVoteError, "El terminal #{voter_fingerprint} ya emitió su voto."
    end
    ```
    *Mecanismo:* Redis maneja internamente un conjunto de valores únicos (*Set*). El comando `SADD` intenta insertar el identificador del votante. Si el identificador ya existía, Redis retorna `0` en tiempo $O(1)$ sin modificar nada, permitiendo detectar de forma inmediata y sin condiciones de carrera (*race conditions*) que el usuario ya votó.
2.  **Incremento Atómico de Votos con `HINCRBY`:**
    ```ruby
    @redis.hincrby("poll:#{poll_id}:options", option_id, 1)
    ```
    *Mecanismo:* Suma 1 de forma atómica en el campo correspondiente del Hash de opciones. No requiere transacciones complejas ni bloqueos de lectura/escritura a nivel de tabla.
3.  **Auditoría Individual:** Guarda un Hash `vote:{uuid}` con la marca de tiempo y los datos del voto para trazabilidad.
4.  **Método de Reinicio (`reset_poll`):** Restablece los contadores de opciones a cero y elimina el Set de votantes para permitir reejecutar pruebas en vivo cuantas veces sea necesario.

---

### 3.4. Capa de Aplicación: Casos de Uso

#### A. Caso de Uso Principal: `RegisterVote` (`app/core/use_cases/register_vote.rb`)
Implementa el flujo funcional completo de extremo a extremo (*End-to-End*):
1.  **Paso 1:** Consulta al repositorio para validar la existencia de la votación (`find_poll`). Si no existe, lanza `PollNotFoundError`.
2.  **Paso 2:** Valida que la sesión esté abierta (`poll.open?`). Si está cerrada, lanza `PollClosedError`.
3.  **Paso 3:** Obtiene las opciones de la votación y valida que la alternativa seleccionada sea válida. Si no, lanza `InvalidOptionError`.
4.  **Paso 4:** Invoca al repositorio para persistir atómicamente el voto. Si el usuario ya votó, el repositorio eleva `DuplicateVoteError`.
5.  **Paso 5:** Emite una notificación reactiva mediante WebSockets (`@broadcaster.broadcast("voting_session", payload)`), enviando los nuevos totales y porcentajes consolidados a todos los clientes conectados.

#### B. Caso de Uso de Consulta: `GetPollResults` (`app/core/use_cases/get_poll_results.rb`)
Consulta el estado de una votación, sus opciones y los porcentajes actuales calculados en memoria.

---

### 3.5. Mecanismos de Entrega: WebSockets (ActionCable) y REST API

#### A. Canal WebSocket: `VotingChannel` (`app/channels/voting_channel.rb`)
Actúa como el adaptador de entrada bidireccional:
*   `subscribed`: Suscribe al cliente al canal `voting_session` y le transmite de forma inmediata el estado actual de la votación (`session_state`), permitiendo que la interfaz gráfica pinte las opciones y barras de progreso apenas arranca.
*   `cast_vote(data)`: Desempaqueta el mensaje JSON enviado por la aplicación de escritorio en Python, invoca al caso de uso `RegisterVote` y captura las excepciones de dominio para responder con mensajes estructurados:
    *   En caso de éxito: Emite `vote_accepted` al emisor y propaga `results_updated` a todos los terminales.
    *   En caso de error de negocio: Transmite `{ event: "vote_error", message: e.message }` únicamente al cliente que originó el intento inválido.
*   `reset_poll(data)`: Permite reiniciar la sesión y notifica la actualización a todos los participantes en tiempo real.

#### B. Controlador REST: `PollsController` (`app/controllers/polls_controller.rb`)
Provee endpoints HTTP complementarios:
*   `GET /polls/:id`: Retorna la información de la votación en formato JSON.
*   `POST /polls/:id/vote`: Endpoint REST alternativo para emitir votos mediante HTTP.
*   `POST /polls/:id/reset`: Endpoint HTTP para reiniciar la sesión.

---

## 4. Diagrama del Flujo de Ejecución Interno

```text
Cliente Desktop (Python WebSocket)
       |
       | 1. Mensaje JSON {action: "cast_vote", poll_id: "1", option_id: "opt_A", fingerprint: "usr_1"}
       v
VotingChannel (Adaptador de Entrega / ActionCable)
       |
       | 2. Invoca execute(poll_id, option_id, fingerprint)
       v
RegisterVote (Caso de Uso de Dominio)
       |
       |-- 3. find_poll("1") ----------> RedisVoteRepository ---> Redis (HGETALL poll:1)
       |                                (Valida estado open?)
       |
       |-- 4. find_options("1") -------> RedisVoteRepository ---> Redis (HGETALL poll:1:options)
       |                                (Valida opcion valida)
       |
       |-- 5. record_vote(...) --------> RedisVoteRepository
                                               |
                                               |-- 6. SADD poll:1:voters "usr_1"
                                               |      (Retorna 1: Voto unico aceptado)
                                               |
                                               |-- 7. HINCRBY poll:1:options opt_A 1
                                               |      (Suma atomica O(1))
                                               |
                                               v
ActionCable.server.broadcast <-----------------+ Retorna totales consolidados
       |
       | 8. WebSocket Push {event: "results_updated", totals: {...}}
       v
Todos los Terminales Desktop Conectados (Actualizan gráficas en vivo)
```

---

## 5. Cumplimiento de Criterios de la Rúbrica

*   Modelado de mínimo 3 entidades de negocio interrelacionadas (`Poll`, `Option`, `Vote`): **Cumplido al 100%**.
*   Flujo funcional completo de extremo a extremo (*End-to-End*): **Cumplido al 100%**.
*   Gestión real de datos en el motor seleccionado (Redis): **Cumplido al 100% con operaciones atómicas**.
*   Manejo de errores y validaciones de robustez (sesión cerrada, votante duplicado, opción inválida): **Cumplido al 100%**.
