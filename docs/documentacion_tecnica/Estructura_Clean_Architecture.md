# Mapeo Estructural: Clean Architecture en DecisionRoom G3

Este documento presenta la correlacion exacta entre el arbol de directorios del proyecto y los circulos concentricos del estilo arquitectonico **Clean Architecture** (Puertos y Adaptadores / Arquitectura Hexagonal).

---

## 1. Estructura del Backend (Ruby on Rails + Redis)

```text
backend/
├── app/
│   │
│   ├── core/                               <── CAPA CENTRAL (DOMINIO Y REGLAS DE NEGOCIO)
│   │   ├── entities/                       <── CAPA 1: ENTIDADES DE DOMINIO (Enterprise Business Rules)
│   │   │   ├── poll.rb                     ──> Entidad pura PORO: Modela la sesion, titulo y estado (abierta/cerrada)
│   │   │   ├── option.rb                   ──> Entidad pura PORO: Modela cada alternativa seleccionable de la mocion
│   │   │   └── vote.rb                     ──> Entidad pura PORO: Modela el registro inmutable de auditoria del voto
│   │   │
│   │   ├── errors.rb                       ──> DOMAIN ERRORS: Excepciones de negocio (DuplicateVoteError, PollClosedError)
│   │   │
│   │   └── use_cases/                      <── CAPA 2: CASOS DE USO (Application Business Rules)
│   │       ├── register_vote.rb            ──> Caso de Uso: Orquesta validacion, persistencia atomica y broadcast
│   │       └── get_poll_results.rb         ──> Caso de Uso: Orquesta consulta y calculo reactivo de porcentajes
│   │
│   ├── infrastructure/                     <── CAPA 3: ADAPTADORES DE INFRAESTRUCTURA (Driven / Outbound Adapters)
│   │   └── repositories/
│   │       └── redis_vote_repository.rb    ──> Adaptador de Persistencia: Implementa operaciones atomicas (SADD, HINCRBY)
│   │
│   ├── channels/                           <── CAPA 3: ADAPTADORES DE ENTREGA PUSH (Driving / Inbound Adapters)
│   │   ├── application_cable/
│   │   │   ├── channel.rb                  ──> Base de canales de ActionCable
│   │   │   └── connection.rb               ──> Identificacion y ciclo de vida de la conexion WebSocket
│   │   └── voting_channel.rb               ──> Adaptador WebSocket: Conecta eventos de red con Casos de Uso
│   │
│   └── controllers/                        <── CAPA 3: ADAPTADORES DE ENTREGA HTTP (Driving / Inbound Adapters)
│       ├── application_controller.rb       ──> Controlador API base sin vistas HTML
│       └── polls_controller.rb             ──> Adaptador REST: Endpoints de consulta y contingencia (Fallback HTTP)
│
├── config/                                 <── CAPA 4: FRAMEWORKS Y DRIVERS (Herramientas y Configuracion Externa)
│   ├── routes.rb                           ──> Enrutador de Rails y montaje de ActionCable en /cable
│   ├── puma.rb                             ──> Servidor web concurrente enlazado a 0.0.0.0:3000
│   ├── cable.yml                           ──> Adaptador pub/sub de ActionCable con Redis
│   └── initializers/
│       ├── clean_architecture.rb           ──> Carga deterministica de POROs ignorando Zeitwerk
│       ├── redis.rb                        ──> Driver cliente Redis y seeding de datos iniciales
│       └── cors.rb                         ──> Politica de acceso cruzado HTTP (CORS)
│
├── Dockerfile                              ──> Contenedor de ejecucion: Entorno aislado en Alpine Linux
└── Gemfile                                 ──> Manifiesto de dependencias (Rails 7 API, sin ActiveRecord)
```

### Tabla de Correspondencia Arquitectonica (Backend)

| Capa de Clean Architecture | Directorio / Archivo | Rol en el Patron de Puertos y Adaptadores |
| :--- | :--- | :--- |
| **Capa 1: Entidades** | `app/core/entities/*.rb`<br>`app/core/errors.rb` | **Nucleo del Dominio:** Objetos puros sin dependencias de base de datos ni frameworks. Reglas de negocio intrinsecas. |
| **Capa 2: Casos de Uso** | `app/core/use_cases/*.rb` | **Puertos de Entrada:** Clases de proposito unico (`RegisterVote`, `GetPollResults`) que dirigen el flujo del sistema. |
| **Capa 3: Adaptadores (Salida)** | `app/infrastructure/repositories/*.rb` | **Adaptador de Persistencia (Driven):** Satisface el contrato de acceso a datos mediante primitivas en memoria de Redis. |
| **Capa 3: Adaptadores (Entrada)** | `app/channels/voting_channel.rb`<br>`app/controllers/polls_controller.rb` | **Adaptadores de Entrega (Driving):** Reciben estimulos externos (WebSockets y HTTP REST) y los traducen a los Casos de Uso. |
| **Capa 4: Frameworks y Drivers** | `config/*`, `Dockerfile`, Puma | **Mecanismos Externos:** Herramientas de ejecucion, red y servidor reemplazables sin afectar el negocio. |

---

## 2. Estructura del Frontend Desktop (Python + Eel + Web UI)

```text
frontend_desktop/
│
├── main.py                                 <── CONTROLADOR Y ADAPTADOR PRINCIPAL DE ESCRITORIO
│   │
│   ├── [Subproceso asyncio (WebSockets)]    ──> Adaptador de Red (Inbound/Outbound):
│   │   │                                       Mantiene conexion TCP duplex persistente con ActionCable (/cable)
│   │   ├── Handshake de bienvenida             Recibe 'welcome' y envia suscripcion a 'VotingChannel'
│   │   ├── Bucle de lectura de eventos         Recibe 'results_updated', 'vote_accepted' y despacha a la UI
│   │   └── Reconexion automatica continua      Reintenta conexion en caso de corte de red sin cerrar la app
│   │
│   ├── [Cola Concurrente (asyncio.Queue)]   ──> Desacoplamiento de Hilos:
│   │   └── outbound_queue                      Transmite votos desde el hilo sincrono de Eel hacia el socket asincrono
│   │
│   ├── [Consultas Directas HTTP Fallback]  ──> Adaptador de Precarga:
│   │   └── fetch_initial_poll_data()           Consulta /polls/1 para renderizar el estado inicial sin latencia
│   │
│   └── [Funciones Puente (@eel.expose)]     ──> Puerto de Comunicacion Inter-Proceso:
│       ├── send_vote(poll_id, option_id)       Expone envio de voto desde JavaScript hacia Python
│       ├── reset_session(poll_id)              Expone orden de reinicio desde JavaScript hacia Python
│       └── request_initial_state()             Expone sincronizacion de terminal ID y estado general
│
├── web/                                    <── CAPA DE PRESENTACION VISUAL (GUI LOCAL EN BROWSER ENGINE)
│   │
│   ├── index.html                          ──> Vista Declarativa (DOM Semantico):
│   │                                           Badges de conexion/nodo, tarjeta de sesion, barras de progreso y botones
│   │
│   ├── css/
│   │   └── styles.css                      ──> Sistema de Diseño y Estado Visual:
│   │                                           Paleta Dark Mode, contrastes semanticos y animaciones reactivas de barras
│   │
│   └── js/
│       └── app.js                          ──> ViewModel / Controlador de Vista en el Cliente:
│           ├── Funciones Expuestas a Python    Recibe broadcasts del socket y actualiza el DOM en tiempo real
│           ├── applyTotals()                   Calcula ancho de barras y porcentajes dinamicos
│           ├── onVoteClick()                   Gestiona eventos del usuario y bloquea doble clic en frontend
│           └── disableVoteButtons()            Preserva texto original de opciones y deshabilita botones post-voto
│
├── requirements.txt                        <── Dependencias del Cliente (Eel, websockets, python-dotenv, pyinstaller)
├── .env.example                            <── Configuracion de entorno (WS_BACKEND_URL, CLIENT_NODE_ID)
└── build_executable.bat                    <── Automatizacion de compilacion a binario standalone (.exe)
```

### Tabla de Correspondencia Arquitectonica (Frontend Desktop)

| Componente del Frontend | Archivo / Modulo | Responsabilidad Arquitectonica |
| :--- | :--- | :--- |
| **Adaptador de Red (WebSocket Client)** | `main.py` (`websocket_listener`) | Gestiona el protocolo TCP persistente con ActionCable, deserializa payloads JSON y tolera fallos de red. |
| **Adaptador Inter-Capa (Eel Bridge)** | `main.py` (`@eel.expose`) | Puertos y adaptadores locales: permite la invocacion segura entre el runtime de Python y el motor de JavaScript. |
| **Controlador de Vista (ViewModel)** | `web/js/app.js` | Mantiene el estado local de la terminal (`hasVotedInSession`), maneja la reactividad de las barras y previene el fraude en el cliente. |
| **Vista Pura (UI)** | `web/index.html`<br>`web/css/styles.css` | Capa mas externa de presentacion: estructura visual desacoplada que puede ser reemplazada sin tocar la logica de Python. |
| **Driver de Empaquetado** | `build_executable.bat` | Empaqueta el cliente en un ejecutable monolitico de escritorio para distribucion sin dependencias locales. |
