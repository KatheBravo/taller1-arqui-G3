# Sistema de Votación y Toma de Decisiones en Tiempo Real (DecisionRoom G3)
## Documento Técnico, Arquitectónico y de Investigación

**Estilo Arquitectónico:** Clean Architecture (Arquitectura Limpia)  
**Stack Tecnológico Asignado:**
*   Frontend: Aplicación de Escritorio con Electron + Python (Eel)
*   Backend: Ruby on Rails (Modo API desacoplado)
*   Persistencia: Redis (In-Memory Data Store)
*   Protocolo de Integración: WebSockets (Bidireccional en tiempo real)
*   Infraestructura: Docker / Docker Compose

---

## 1. Investigación del Estilo y Stack Tecnológico

### 1.1. Estilo Arquitectónico: Clean Architecture

*   **Definición clara (Qué es y qué no es):**
    *   *Qué es:* Clean Architecture es un modelo arquitectónico de software formalizado por Robert C. Martin ("Uncle Bob") en 2012. Se fundamenta en la estructuración del código en capas concéntricas regidas por la **Regla de Dependencia**, la cual establece que las dependencias del código fuente solo pueden apuntar hacia adentro, hacia las políticas de más alto nivel (el dominio).
    *   *Qué no es:* No es una biblioteca, no es una plantilla de carpetas rígida impuesta por un framework, ni tampoco es un patrón de diseño a nivel de clases como MVC o Singleton. Es un paradigma estructural de gestión de dependencias y aislamiento de responsabilidades.
*   **Clasificación del estilo:**
    *   Se clasifica como un **estilo arquitectónico estructural y modular**, perteneciente a la familia de arquitecturas basadas en la *Separación de Intereses (Separation of Concerns)* y *Puertos y Adaptadores*. Es la evolución directa de la Arquitectura Hexagonal (Alistair Cockburn, 2005) y la Onion Architecture (Jeffrey Palermo, 2008).
*   **Características principales:**
    *   *Independencia de Frameworks:* La arquitectura no depende de la existencia de Rails, Django, Spring o cualquier librería externa; los frameworks son tratados como detalles de implementación.
    *   *Independencia de la UI:* La interfaz gráfica (Electron/Python) puede ser sustituida por una interfaz de línea de comandos (CLI) o una API REST sin alterar una sola regla de negocio.
    *   *Independencia de la Base de Datos:* La lógica empresarial desconoce si los datos se almacenan en Redis, PostgreSQL o un archivo plano.
    *   *Alta Testabilidad:* Los casos de uso y las entidades de negocio pueden someterse a pruebas unitarias automatizadas sin necesidad de levantar bases de datos, servidores web o conexiones de red activas.
*   **Historia y evolución:**
    *   Históricamente, los sistemas de software sufrían del "Gran Bola de Lodo" (*Big Ball of Mud*) y del acoplamiento severo a esquemas de bases de datos relacionales propiciado por los ORM tradicionales de los años 2000. Cockburn introdujo los Puertos y Adaptadores en 2005 para aislar el núcleo del mundo exterior. En 2008, Palermo formuló Onion Architecture enfatizando la inversión de dependencias. Finalmente, en 2012 Uncle Bob sintetizó estas corrientes bajo el nombre *Clean Architecture*, estandarizando la división en cuatro anillos concéntricos: Entidades, Casos de Uso, Adaptadores de Interfaz y Mecanismos de Entrega/Infraestructura.
*   **Ventajas y desventajas:**
    *   *Ventajas:* Excelente mantenibilidad a mediano y largo plazo, bajo acoplamiento técnico, capacidad para sustituir piezas tecnológicas obsoletas sin refactorizar el negocio y aislamiento total para pruebas unitarias de ejecución rápida.
    *   *Desventajas:* Introduce una marcada complejidad accidental en etapas iniciales. Requiere la creación de mapeadores, interfaces abstractas y Objetos de Transferencia de Datos (DTOs), lo que ralentiza el desarrollo temprano (*Time to Market*) y contradice enfoques pragmáticos en proyectos simples.
*   **Problemas comunes que se presentan y patrones asociados:**
    *   *Fuga de infraestructura al dominio (Leakage):* Ocurre cuando tipos de datos nativos de la base de datos o parámetros HTTP se inyectan en los casos de uso. Solución/Patrón: Se implementa el patrón **DTO (Data Transfer Object)** y objetos de valor inmutables.
    *   *Acoplamiento en la instanciación:* Ocurre cuando un caso de uso instancia directamente la clase concreta de persistencia. Solución/Patrón: Se resuelve mediante el principio de **Inversión de Dependencias (DIP)** e **Inyección de Dependencias (IoC / Dependency Injection Containers)**.
*   **Identificar patrones aplicables y cuándo usarlos:**
    *   *Patrón Repositorio (Repository Pattern):* Se utiliza en la frontera entre los casos de uso y el almacenamiento para mediar entre la capa de dominio y las operaciones de datos sobre Redis, exponiendo contratos abstractos (`save`, `find_by_id`, `record_vote`).
    *   *Patrón Interactor / Caso de Uso:* Modela cada interacción del usuario como un objeto de comando único y comprobable (ej. `RegisterVoteUseCase`).
*   **Casos de uso (Cuándo usarlo y cuándo no):**
    *   *Cuándo usarlo:* Sistemas empresariales con lógica de negocio intrincada, plataformas con múltiples canales de entrada (web, móvil, escritorio, eventos), aplicaciones de larga vida útil y proyectos donde el stack tecnológico externo deba evolucionar con el tiempo.
    *   *Cuándo no usarlo:* Aplicaciones CRUD sencillas, pruebas de concepto rápidas (POC), prototipos desechables (MVPs) o sistemas donde el valor radica en el framework y no en la lógica propia.
*   **Casos de aplicación en la industria:**
    *   Sector FinTech global (bancos digitales como Nubank, Revolut y N26) donde las reglas de cumplimiento financiero y cálculo contable deben permanecer 100% aisladas de los cambios en los proveedores de nube o bases de datos subyacentes.

---

### 1.2. Tecnologías del Stack Asignado

#### Frontend: Electron + Python (Eel)
*   **Definición clara:** Eel es una librería de Python orientada a construir interfaces gráficas de usuario basadas en tecnologías web (HTML, CSS, JS) ejecutándose en una ventana de navegador embebida (Chromium/Chrome) o integrada con el runtime de Electron. No es un generador de binarios nativos en C/C++ ni aloja sitios web públicos remotos; es un puente de Comunicación Inter-Procesos (IPC) local bidireccional entre Python y el motor de renderizado web.
*   **Características principales:** Portabilidad multiplataforma inmediata, interoperabilidad bidireccional mediante decoradores (`@eel.expose`), acceso a todas las librerías del ecosistema Python y empaquetado para distribución en ejecutables locales.
*   **Historia y evolución:** Tradicionalmente, crear interfaces en Python obligaba a usar librerías visualmente anticuadas como Tkinter o complejas como PyQt. Con la hegemonía de Electron y Chromium para aplicaciones como VS Code y Slack, surgieron alternativas ligeras como Eel y Pywebview para permitir que desarrolladores de Python utilizaran HTML5/CSS moderno sin obligarse a escribir toda la lógica de aplicación en Node.js.
*   **Ventajas y desventajas:**
    *   *Ventajas:* Permite diseñar interfaces modernas y reactivas con HTML/CSS mientras toda la computación local, manejo de sockets de red y acceso a hardware permanece en Python.
    *   *Desventajas:* Mayor consumo de memoria RAM por el motor Chromium en comparación con widgets nativos del sistema operativo.
*   **Casos de uso:** Paneles de control para salas de decisión, estaciones de trabajo industriales, software de monitoreo de laboratorios y herramientas internas corporativas. Inadecuado para microcontroladores o software con restricciones críticas de memoria RAM (< 100 MB).
*   **Casos de aplicación:** Herramientas de visualización de datos científicos, terminales de control de subastas y software de streaming y producción audiovisual.

#### Backend: Ruby on Rails (Modo API)
*   **Definición clara:** Es un framework de desarrollo de aplicaciones web de código abierto escrito en Ruby. Diseñado bajo los principios de *Convención sobre Configuración* (CoC) y *Don't Repeat Yourself* (DRY), Rails proporciona toda la infraestructura para construir servicios web robustos. No es un simple micro-enrutador HTTP ni un lenguaje de bajo nivel; es una suite completa de desarrollo de software para el servidor.
*   **Características principales:** Alta productividad y expresividad sintáctica, soporte nativo para generación de APIs ligeras (`--api`), modularidad de middleware y soporte integrado de WebSockets a través de ActionCable.
*   **Historia y evolución:** Creado por David Heinemeier Hansson en 2003 a partir del código de Basecamp. Revolucionó la industria del software al introducir convenciones que luego adoptaron frameworks de otros lenguajes (Laravel, Django, Grails). Con las versiones 5, 6 y 7, Rails integró soporte de primer nivel para APIs desacopladas y canales de WebSockets reactivos.
*   **Ventajas y desventajas:**
    *   *Ventajas:* Excepcional velocidad de desarrollo, ecosistema de gemas maduro y estabilidad comprobada en producción.
    *   *Desventajas:* Su fuerte tendencia natural al acoplamiento mediante ActiveRecord exige un esfuerzo disciplinado para respetar las fronteras puras de Clean Architecture.
*   **Casos de uso:** APIs de alto rendimiento funcional, plataformas SaaS y núcleos transaccionales orientados a eventos. Inadecuado para procesamiento matemático paralelo a bajo nivel o modelos masivos de Deep Learning donde lenguajes compilados o C-extensions son mandatorios.
*   **Casos de aplicación:** GitHub, Shopify, GitLab, Airbnb y Basecamp.

#### Persistencia: Redis (Remote Dictionary Server)
*   **Definición clara:** Es un motor de almacenamiento de estructuras de datos en memoria (In-Memory), de código abierto, utilizado como base de datos clave-valor de latencia ultra baja, sistema de caché y bróker de mensajería (Pub/Sub). No es un motor relacional basado en tablas SQL ni un sistema de almacenamiento masivo en frío para discos duros mecánicos.
*   **Características principales:** Tiempos de respuesta submilimétricos (microsegundos), operaciones atómicas sobre tipos de datos ricos (Hashes, Sets, Sorted Sets, Strings), persistencia opcional a disco (RDB y AOF) y soporte nativo para colas y publicación/suscripción.
*   **Historia y evolución:** Creado en 2009 por Salvatore Sanfilippo ("antirez") para optimizar un analizador de logs en tiempo real. Se convirtió en el estándar indiscutible de la industria para datos volátiles de alta velocidad y conteo concurrente.
*   **Ventajas y desventajas:**
    *   *Ventajas:* Velocidad de lectura y escritura inigualable gracias al procesamiento directo en RAM; capacidad nativa de operaciones atómicas (`HINCRBY`, `SADD`) ideales para votaciones y conteos concurrentes sin condiciones de carrera (*race conditions*).
    *   *Desventajas:* Almacenamiento limitado a la memoria RAM disponible física; no soporta consultas relacionales complejas ni joins nativos sin un modelado manual de índices.
*   **Casos de uso:** Tableros de puntuación en vivo (*Leaderboards*), conteo de votos en tiempo real, administración de sesiones distribuidas y canales de streaming de datos. Inadecuado como almacenamiento histórico documental a largo plazo para terabytes de datos fríos.
*   **Casos de aplicación:** Twitter (conteo de métricas e impresiones), StackOverflow (manejo de sesiones y caché de preguntas) y plataformas financieras de alta frecuencia.

#### Protocolo de Integración: WebSockets
*   **Definición clara:** Es un protocolo de comunicación estandarizado por la IETF (RFC 6455) que establece un canal de transmisión full-duplex y bidireccional sobre una única conexión TCP persistente entre cliente y servidor. No es una variante de peticiones HTTP repetitivas (como el *Polling* o *Long-Polling*), sino un protocolo independiente que realiza un apretón de manos inicial (*Handshake*) sobre HTTP y luego conmuta a una conexión TCP directa continua.
*   **Características principales:** Latencia mínima de red, eliminación de la sobrecarga de cabeceras HTTP en cada mensaje, y capacidad del servidor para empujar datos al cliente de manera instantánea (*Server Push*) en el momento en que ocurre un evento.
*   **Historia y evolución:** Antes de su estandarización en 2011, la web reactiva dependía de hacks ineficientes como el polling periódico que saturaba los servidores con encabezados redundantes. WebSockets habilitó la era moderna de colaboración reactiva instantánea.
*   **Ventajas y desventajas:**
    *   *Ventajas:* Comunicación fluida y bidireccional ideal para arquitecturas reactivas orientadas a eventos en tiempo real.
    *   *Desventajas:* Requiere mantener conexiones TCP abiertas en memoria del servidor, demandando una arquitectura de concurrencia adecuada y mecanismos de reconexión automática en los clientes.
*   **Casos de uso:** Votaciones y asambleas en vivo, salas de chat, subastas electrónicas y dashboards de telemetría. Innecesario y sobrecostoso para operaciones de consulta estática o reportes por lotes.
*   **Casos de aplicación:** Google Docs (edición colaborativa), TradingView (cotizaciones bursátiles en vivo) y Discord (estado de presencia y mensajería).

---

### 1.3. Relación entre el Estilo y las Tecnologías Seleccionadas

La coexistencia de **Clean Architecture** con este stack particular responde a una necesidad técnica clara:
1.  **Aislamiento de la lógica respecto al protocolo:** La lógica de negocio (`app/core/use_cases`) no sabe ni le interesa si la solicitud provino de un WebSocket o de una llamada HTTP REST. El controlador de WebSockets actúa estrictamente como un **Adaptador de Entrada (Delivery Mechanism)** que desempaqueta el payload JSON, ejecuta el caso de uso y recibe una entidad pura o DTO.
2.  **Inversión de dependencias sobre Redis:** En lugar de acoplar el sistema a las clases de Redis, el dominio define una interfaz/puerto (`VoteRepository`). La infraestructura implementa dicho contrato (`RedisVoteRepository`) valiéndose de operaciones atómicas en memoria. Si mañana se decidiera migrar a PostgreSQL, los Casos de Uso y las Entidades permanecerían 100% inalterados.
3.  **Desacoplamiento entre UI y Backend:** La aplicación de escritorio en Electron + Python actúa como un consumidor externo del sistema distribuido, comunicándose a través del protocolo WebSocket sin ningún acoplamiento a nivel de memoria ni dependencias compartidas de código con Ruby.

---

### 1.4. Qué tan común es el Stack Designado (Análisis del Mercado Técnico)

Se identifican dos polos con niveles de madurez e interoperabilidad muy contrastantes:
*   **Backend + Persistencia + Protocolo (Rails + Redis + WebSockets):** Es un **estándar industrial consolidado**. Ruby on Rails incluye soporte nativo para Redis como adaptador de cola, caché y pub/sub a través de ActionCable, lo que conforma una tríada madura, hiperprobada y utilizada por empresas de escala masiva como Shopify y GitHub.
*   **Frontend (Electron + Python con Eel):** Representa un **nicho especializado de ingeniería**. Lo convencional en Electron es emplear Node.js/TypeScript con React o Vue. Integrar Python como orquestador de la ventana Chromium con Eel es una estrategia adoptada principalmente por ingenieros de datos, investigadores y desarrolladores de Python que requieren una interfaz gráfica rica y moderna sin depender de ecosistemas complejos de JavaScript.
*   **Conclusión de la relación tecnológica:** El stack es un sistema distribuido heterogéneo que pone a prueba la capacidad de diseñar contratos de comunicación limpios (JSON estructurado sobre WebSockets) entre dos entornos de ejecución completamente dispares (Ruby en el servidor y Python en el cliente).

---

### 1.5. Frameworks: Comandos, Estructura y Variables de Entorno

#### Backend: Ruby on Rails (Estructura Limpia sin ActiveRecord)
*   **Comandos de inicialización:**
    ```bash
    # Crear proyecto Rails en modo API omitiendo ActiveRecord (persistencia 100% en Redis)
    rails new backend_votacion --api --skip-active-record --skip-test
    cd backend_votacion

    # Instalar gemas requeridas en Gemfile (redis, dotenv-rails)
    bundle add redis dotenv-rails
    ```
*   **Estructura de directorios adaptada a Clean Architecture:**
    ```text
    backend_votacion/
    ├── app/
    │   ├── channels/                 # Adaptador WebSocket (ActionCable / WebSockets)
    │   │   ├── application_cable/
    │   │   └── voting_channel.rb     # Entrada de eventos desde clientes
    │   ├── controllers/              # Mecanismo de entrega HTTP (si aplica)
    │   ├── core/                     # NUCLEO INDEPENDIENTE (Clean Domain)
    │   │   ├── entities/             # Entidades puras de negocio (Ruby POROs)
    │   │   │   ├── poll.rb
    │   │   │   ├── option.rb
    │   │   │   └── vote.rb
    │   │   └── use_cases/            # Reglas de negocio de la aplicación
    │   │       ├── register_vote.rb
    │   │       └── get_poll_results.rb
    │   └── infrastructure/           # Adaptadores de salida
    │       └── repositories/         # Implementación de puertos sobre Redis
    │           └── redis_vote_repository.rb
    ├── config/
    │   ├── cable.yml                 # Configuración de ActionCable con Redis
    │   └── initializers/redis.rb     # Pool de conexión a Redis
    ├── .env                          # Variables de entorno
    └── Dockerfile
    ```
*   **Manejo de variables de entorno:**
    Archivo `.env` en la raíz del backend:
    ```env
    PORT=3000
    REDIS_URL=redis://localhost:6379/0
    ALLOWED_ORIGINS=*
    ```

#### Frontend: Electron + Python (Eel)
*   **Comandos de inicialización y empaquetado:**
    ```bash
    # Creación del entorno virtual e instalación de librerías
    python -m venv venv
    venv\Scripts\activate          # En Windows
    pip install eel websockets python-dotenv

    # Compilación a binario ejecutable independiente (modo producción)
    python -m eel main.py web --onefile --noconsole --name DecisionRoom
    ```
*   **Estructura de directorios:**
    ```text
    frontend_desktop/
    ├── main.py                       # Orquestador Python (Eel + WebSocket Client)
    ├── web/                          # Interfaz gráfica renderizada por Chromium
    │   ├── index.html                # Estructura del panel de decisión / votación
    │   ├── css/
    │   │   └── styles.css            # Estilos visuales
    │   └── js/
    │       └── app.js                # Lógica de UI (listeners del DOM y actualización de barras)
    ├── .env                          # Variables de configuración del cliente
    └── requirements.txt
    ```
*   **Manejo de variables de entorno:**
    Archivo `.env` en el cliente:
    ```env
    WS_BACKEND_URL=ws://127.0.0.1:3000/cable
    CLIENT_NODE_ID=terminal_mesa_1
    RECONNECT_INTERVAL_SECONDS=3
    ```

---

## 2. Análisis Arquitectónico

### 2.1. Matriz de Atributos de Calidad vs Estilo (Clean Architecture)

| Atributo de Calidad | ¿El estilo lo soporta o limita? | Justificación Técnica |
| :--- | :---: | :--- |
| **Mantenibilidad** | **Lo soporta (Alto)** | Al aislar las reglas de negocio en Casos de Uso y Entidades, los cambios en los mecanismos de entrega (WebSockets) o persistencia (Redis) no alteran el core funcional. |
| **Testabilidad** | **Lo soporta (Alto)** | La Inversión de Dependencias permite realizar pruebas unitarias sobre los casos de uso inyectando Mocks o repositorios en memoria sin requerir Redis ni servidores activos. |
| **Modificabilidad / Flexibilidad** | **Lo soporta (Alto)** | Cambiar el motor de persistencia o agregar nuevos clientes de escritorio se realiza mediante nuevos adaptadores sin tocar una sola línea del dominio. |
| **Rendimiento (Performance)** | **Lo limita (Leve)** | La necesidad de transformar datos entre entidades de dominio, DTOs y estructuras de red agrega una pequeña sobrecarga computacional frente a accesos directos acoplados. |
| **Simplicidad (KISS / Time to Market)** | **Lo limita (Alto)** | Exige escribir múltiples interfaces, clases adaptadoras y DTOs para operaciones simples, aumentando la complejidad accidental inicial en proyectos pequeños. |

---

### 2.2. Matriz de Análisis de Principios vs Estilo

| Principio | ¿El estilo lo cumple? | Justificación Técnica |
| :--- | :---: | :--- |
| **SOLID - SRP** (Single Responsibility) | **Sí** | Cada Caso de Uso atiende una única intención del negocio (ej. `RegisterVote`), y cada adaptador gestiona un único medio técnico. |
| **SOLID - OCP** (Open/Closed) | **Sí** | Se pueden añadir nuevos repositorios (ej. `PostgresVoteRepository`) extendiendo los contratos existentes sin modificar el caso de uso. |
| **SOLID - LSP** (Liskov Substitution) | **Sí** | Cualquier implementación de `VoteRepository` puede sustituir a otra sin quebrantar la lógica del caso de uso. |
| **SOLID - ISP** (Interface Segregation) | **Sí** | Se definen puertos específicos y pequeños adaptados a las necesidades del caso de uso en lugar de interfaces monolíticas. |
| **SOLID - DIP** (Dependency Inversion) | **Sí (Pilar)** | Los módulos de alto nivel (casos de uso) no dependen de módulos de bajo nivel (Redis/ActionCable); ambos dependen de abstracciones. |
| **KISS** (Keep It Simple, Stupid) | **No (Lo rompe)** | Clean Architecture sacrifica la simplicidad en favor de la extensibilidad, introduciendo múltiples capas y abstracciones. |
| **DRY** (Don't Repeat Yourself) | **Parcialmente** | Evita la duplicación de lógica de negocio, pero **obliga a replicar modelos de datos** (Entidades de dominio vs DTOs de red vs estructuras de Redis). |
| **YAGNI** (You Aren't Gonna Need It) | **No (Lo rompe)** | Crea capas de abstracción para componentes que probablemente nunca serán sustituidos en proyectos académicos o de corta vida. |
| **PoLA** (Principle of Least Astonishment) | **Sí** | La convención concéntrica garantiza que el flujo de control y la ubicación de las reglas sean predecibles para cualquier ingeniero. |
| **Ley de Demeter** | **Sí** | Los DTOs aseguran que los componentes sólo interactúen con estructuras directas, evitando llamadas en cadena acopladas. |
| **STUPID** (Antipatrones) | **Los previene** | Previene activamente el acoplamiento fuerte (*Tight Coupling*) y la falta de testabilidad (*Untestability*) mediante inyección de dependencias. |
| **Composición sobre Herencia** | **Sí** | Los Casos de Uso no heredan clases base del framework (`ActionController::Base`), sino que se componen inyectando dependencias. |

---

### 2.3. Matriz de Análisis de Tácticas vs Estilo y Stack (Justificación ADR)

**Contexto del ADR:** *Decisión de Diseño para Concurrencia y Latencia Submilimétrica en la Emisión de Votos.*

| Táctica Arquitectónica | Aplicación en Clean Architecture | Aplicación en el Stack (Rails + Redis + WebSockets) |
| :--- | :--- | :--- |
| **Eficiencia Computacional** | El caso de uso delega las operaciones numéricas críticas a interfaces atómicas. | **Excelente:** Se utiliza la instrucción atómica `HINCRBY` de Redis, procesada en RAM con complejidad algorítmica O(1). |
| **Manejo de Concurrencia** | Casos de uso sin estado (*stateless*), lo que garantiza seguridad en entornos multi-hilo (*thread-safety*). | **Excelente:** El servidor Puma de Rails atiende miles de sockets concurrentes; Redis encola y procesa comandos atómicos sin condiciones de carrera. |
| **Desacoplamiento de Eventos** | El caso de uso emite un evento de dominio (`VoteRegisteredEvent`) sin saber quién lo consume. | **Excelente:** ActionCable y Redis Pub/Sub distribuyen el mensaje a todos los clientes suscritos en milisegundos. |
| **Manejo de Fallas y Recuperación** | Fronteras con manejo explícito de excepciones y validaciones de negocio independientes. | **Buena:** Reconexión automática con retroceso exponencial (*Exponential Backoff*) configurada en el cliente Python ante caídas de red. |

---

### 2.4. Matriz de Mercado Laboral vs Estilo y Stack

*Fuentes consultadas: StackOverflow Developer Survey 2024, GitHub Octoverse, TIOBE Index, Hired State of Software Engineers.*

| Perfil / Tecnología | Demanda Actual | Proyección (5 años) | Salario Promedio Anual (USD) | Salario Mensual Estimado (USD) |
| :--- | :---: | :---: | :---: | :---: |
| **Arquitectura de Software / Clean Arch** | Muy Alta (Senior/Staff) | Creciente (Microservicios y sistemas críticos) | $125,000 - $165,000+ | $10,400 - $13,750 |
| **Python Developer (Ecosistema General)** | Masiva (Top 3 mundial) | Muy Alta (Impulsada por IA y Automatización) | $105,000 - $150,000 | $8,750 - $12,500 |
| **Ruby on Rails Engineer** | Estable / Nicho Rentable | Estable (Mantenimiento de SaaS de alta rentabilidad) | $100,000 - $145,000 | $8,300 - $12,000 |
| **Redis (Especialista en Datos y Caché)** | Alta (Infraestructura) | Alta (Sistemas reactivos y de baja latencia) | $115,000 - $155,000 | $9,500 - $12,900 |
| **Electron / Desktop Software Engineer** | Media / Especializada | Estable (Herramientas corporativas y productividad) | $85,000 - $130,000 | $7,000 - $10,800 |

*Conclusión de Mercado:* Dominar Clean Architecture sitúa al desarrollador en la franja salarial más alta de la industria (roles de liderazgo técnico). Si bien Ruby on Rails no tiene el volumen de vacantes de JavaScript, sus profesionales cuentan con una de las compensaciones más estables del mercado por la naturaleza rentable de las empresas que lo sostienen (Shopify, GitHub, Stripe).

---

## 3. Diseño del Sistema: Guía Paso a Paso para Construcción de Diagramas

En esta sección se detalla el diseño de la solución **DecisionRoom G3**, estructurado con el paso a paso lógico para que el equipo pueda dibujar y sustentar cada diagrama manualmente (en pizarra, diapositivas, Draw.io o papel), explicando la relación y transición entre cada fase.

### Transición Lógica entre las Fases de Diseño

Para sustentar fluidamente frente al docente, se debe seguir esta secuencia narrativa:
1.  **Fase de Información (Modelo de Datos):** Define las entidades del negocio y sus atributos esenciales, demostrando que la solución no es un simple script sino un modelo formal.
2.  **Fase de Alcance Externo (C4 Nivel 1 - Contexto):** Explica quiénes son los usuarios y delimita las fronteras del sistema con el mundo exterior.
3.  **Fase Estructural de Componentes (HLD y C4 Nivel 2 - Contenedores):** Abre la caja del sistema y muestra cómo se reparten las tareas entre la aplicación de escritorio en Python/Electron, el backend Rails y el motor Redis.
4.  **Fase Dinámica y Comportamiento (Diagrama de Secuencia):** Muestra el flujo temporal en vivo cuando un usuario hace clic en "Votar", demostrando el paso por Clean Architecture, Redis y WebSockets.
5.  **Fase de Despliegue Físico (C4 Deployment):** Demuestra cómo se empaquetan y ejecutan los servicios en contenedores Docker reales.

---

### 3.1. Modelo de Datos (3 Entidades de Negocio Interrelacionadas)

#### Objetivo del Diagrama
Demostrar el cumplimiento del requerimiento mínimo de 3 entidades de negocio fuertemente tipadas e interrelacionadas, modeladas de forma pura e independiente del motor de base de datos.

#### Componentes a Dibujar (Tablas / Cajas de Entidad)
1.  **Caja 1: POLL (Votación / Moción)**
    *   `id` (PK, String / UUID): Identificador único de la votación.
    *   `title` (String): Asunto o propuesta a deliberar.
    *   `description` (String): Explicación del debate.
    *   `status` (String): Estado de la sesión (`open`, `closed`).
    *   `created_at` (Timestamp): Fecha y hora de apertura.
2.  **Caja 2: OPTION (Opción de Voto)**
    *   `id` (PK, String): Identificador de la alternativa (ej. `opt_A`, `opt_B`).
    *   `poll_id` (FK, String): Referencia a la votación a la que pertenece.
    *   `text` (String): Descripción textual (ej. "A Favor", "En Contra", "Abstención").
    *   `current_votes` (Integer): Total acumulado de votos en memoria.
3.  **Caja 3: VOTE (Registro de Emisión de Voto)**
    *   `id` (PK, String / UUID): Identificador del evento de voto.
    *   `poll_id` (FK, String): Votación en la que se participó.
    *   `option_id` (FK, String): Opción seleccionada.
    *   `voter_fingerprint` (String): Hash identificador único del terminal o delegado.
    *   `cast_at` (Timestamp): Momento exacto de emisión.

#### Relaciones y Cardinalidad
*   **De POLL a OPTION:** Relación de uno a muchos (1..*). Una votación contiene obligatoriamente una o más opciones. Línea con símbolo de pata de gallo hacia OPTION.
*   **De OPTION a VOTE:** Relación de uno a muchos (1..*). Una opción puede recibir de 0 a múltiples votos. Línea con símbolo de pata de gallo hacia VOTE.

#### Esquema Visual Textual para Dibujar
```text
+-----------------------+           +-----------------------+           +-----------------------+
|         POLL          | 1       * |        OPTION         | 1       * |         VOTE          |
+-----------------------+-----------+-----------------------+-----------+-----------------------+
| PK id                 |  contiene | PK id                 |   recibe  | PK id                 |
|    title              |           | FK poll_id            |           | FK poll_id            |
|    description        |           |    text               |           | FK option_id          |
|    status             |           |    current_votes      |           |    voter_fingerprint  |
|    created_at         |           +-----------------------+           |    cast_at            |
+-----------------------+                                               +-----------------------+
```

#### Mapeo a Estructuras Atómicas de Redis
*   `poll:{id}` -> Tipo **Hash** (metadatos de la votación).
*   `poll:{id}:options` -> Tipo **Hash** (`option_id` como campo, conteo como valor numérico manipulado con `HINCRBY`).
*   `poll:{id}:voters` -> Tipo **Set** (almacena `voter_fingerprint` con `SADD` para validar en tiempo O(1) que no haya votos duplicados).

---

### 3.2. Diagrama de Alto Nivel (HLD)

#### Objetivo del Diagrama
Ofrecer una vista panorámica simple de los tres grandes bloques que conforman la arquitectura y los protocolos que los comunican.

#### Paso a Paso Lógico para Dibujarlo a Mano
1.  **Dibujar a la izquierda** una caja grande titulada **Capa de Presentación (Frontend Desktop)**. Dentro, dibuja dos subcajas conectadas:
    *   Subcaja superior: "Interfaz de Usuario (Chromium / HTML5-CSS-JS)".
    *   Subcaja inferior: "Proceso Local Python (Eel Bridge + WebSocket Client)".
    *   Conecta ambas subcajas con una flecha bidireccional etiquetada como `Llamadas IPC Locales (Eel)`.
2.  **Dibujar en el centro** una caja titulada **Capa de Negocio y Entrega (Ruby on Rails Backend)**. Dentro, dibuja:
    *   "Adaptador WebSocket (ActionCable VotingChannel)".
    *   "Clean Architecture Core (Casos de Uso y Entidades)".
    *   "Adaptador de Repositorio".
    *   Conecta el Adaptador WebSocket con el Core, y el Core con el Repositorio mediante flechas verticales de llamada.
3.  **Dibujar a la derecha** un cilindro titulado **Capa de Persistencia y Eventos (Redis Server)**.
4.  **Trazar las conexiones principales:**
    *   Flecha bidireccional entre el **Proceso Local Python** (Frontend) y el **Adaptador WebSocket** (Rails Backend), con la etiqueta `WebSockets (TCP Persistente / Puerto 3000)`.
    *   Flecha bidireccional entre el **Adaptador de Repositorio** (Rails) y **Redis**, con la etiqueta `Comandos de Datos (TCP / Puerto 6379)`.
    *   Flecha punteada bidireccional entre **Rails** y **Redis**, con la etiqueta `Pub/Sub de Eventos en Tiempo Real`.

#### Esquema Visual Textual para Dibujar
```text
+------------------------------+             +-------------------------------+             +-----------------+
|      FRONTEND DESKTOP        |             |         BACKEND RAILS         |             |      REDIS      |
|  (Terminal de Participante)  |             |      (Servidor Central)       |             |   (En Memoria)  |
|                              |             |                               |             |                 |
|  [ Vista HTML5 / CSS / JS ]  |             |  [ ActionCable WebSocket ]    |             |  +-----------+  |
|              ^               |  WebSocket  |               |               |  Comandos   |  |  Hashes   |  |
|      (IPC)   |               |<===========>|               v               |<===========>|  |  y Sets   |  |
|              v               |  Bidirecc.  |  [ Clean Core: Use Cases ]    |  TCP:6379   |  +-----------+  |
|  [ Proceso Local Python ]    |  Port:3000  |               |               |             |  +-----------+  |
|    (Librería websockets)     |             |               v               |   Pub/Sub   |  |  Pub/Sub  |  |
|                              |             |  [ Repositorio de Datos ]     |< - - - - - >|  |  Canales  |  |
+------------------------------+             +-------------------------------+             +-----------------+
```

---

### 3.3. Diagrama de Contexto (C4 Nivel 1)

#### Objetivo del Diagrama
Representar el sistema como una caja negra central y mostrar cómo interactúan con él los diferentes tipos de usuarios humanos en el entorno de la asamblea.

#### Paso a Paso Lógico para Dibujarlo a Mano
1.  **Dibujar la caja central:** Traza un rectángulo grande con borde grueso en el centro con el título:
    *   `[Sistema de Software] DecisionRoom G3`.
    *   Descripción: "Plataforma de votación y toma de decisiones que coordina mociones, valida reglas de negocio, persiste conteos atómicos y sincroniza resultados en vivo".
2.  **Dibujar a los actores (figuras humanas o cajas de persona):**
    *   A la izquierda: `[Persona] Delegado / Asambleísta`. Descripción: "Miembro del comité que emite votos desde su terminal y observa el comportamiento del escrutinio".
    *   A la derecha o arriba: `[Persona] Moderador / Presidente`. Descripción: "Abre la sesión de debate, define la moción y proyecta las métricas de consenso".
3.  **Trazar las interacciones:**
    *   Flecha del **Delegado** hacia **DecisionRoom G3**: Etiquetada como `Visualiza opciones y emite voto [Desktop App]`.
    *   Flecha del **Sistema** hacia el **Delegado**: Etiquetada como `Notifica actualización de resultados en vivo [WebSockets]`.
    *   Flecha del **Moderador** hacia **DecisionRoom G3**: Etiquetada como `Abre y clausura rondas de votación [Desktop App]`.

#### Esquema Visual Textual para Dibujar
```text
           +-----------------------------+
           |    Moderador / Presidente   |
           |     (Rol Administrativo)    |
           +-----------------------------+
                          |
                          | Abre / Cierra sesiones
                          v
+------------------+             +-----------------------------------------+
|     Delegado     |  Emite Voto |          [SISTEMA CENTRAL C4]           |
|  (Participante)  |------------>|             DecisionRoom G3             |
|                  |<------------|                                         |
+------------------+  Resultados | Gestiona sesiones, persiste en memoria  |
                        en vivo   | y sincroniza el escrutinio en vivo      |
                                 +-----------------------------------------+
```

---

### 3.4. Diagrama de Contenedores (C4 Nivel 2)

#### Objetivo del Diagrama
Abrir la frontera del sistema DecisionRoom G3 y exponer sus contenedores de software ejecutables por separado, indicando las tecnologías asignadas y sus canales de enlace.

#### Paso a Paso Lógico para Dibujarlo a Mano
1.  **Dibujar el límite del sistema:** Traza un gran recuadro punteado que englobe todo, titulado `Límite de DecisionRoom G3`.
2.  **Dibujar el Contenedor 1 (Frontend):**
    *   Caja titulada `Terminal de Escritorio`.
    *   Tecnología: `Electron + Python (Eel)`.
    *   Descripción: "Provee la interfaz gráfica moderna en Chromium y orquesta la conexión TCP de WebSockets desde Python".
3.  **Dibujar el Contenedor 2 (Backend):**
    *   Caja titulada `Backend Core Application`.
    *   Tecnología: `Ruby on Rails (Modo API, Ruby 3.x)`.
    *   Descripción: "Aloja las entidades de Clean Architecture, ejecuta los casos de uso de negocio y gestiona el canal ActionCable".
4.  **Dibujar el Contenedor 3 (Persistencia):**
    *   Forma de cilindro titulada `Base de Datos en Memoria`.
    *   Tecnología: `Redis 7.x`.
    *   Descripción: "Almacena datos clave-valor de votaciones, registros de unicidad y sirve como bróker Pub/Sub".
5.  **Trazar las conexiones entre contenedores:**
    *   Línea de **Terminal de Escritorio** a **Backend Core Application**: Etiqueta `Envía votos y escucha eventos [WebSockets / JSON sobre TCP:3000]`.
    *   Línea de **Backend Core Application** a **Base de Datos en Memoria**: Etiqueta `Lee / Escribe conteos atómicos [Protocolo Redis sobre TCP:6379]`.
    *   Línea de retorno punteada de **Base de Datos** a **Backend**: Etiqueta `Distribución de eventos entre hilos [Redis Pub/Sub]`.

#### Esquema Visual Textual para Dibujar
```text
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
: Límite del Sistema DecisionRoom G3                                                            :
:                                                                                               :
:  +---------------------------------+                 +-------------------------------------+  :
:  |     TERMINAL DE ESCRITORIO      |                 |       BACKEND CORE APPLICATION      |  :
:  |    [Electron + Python (Eel)]    |                 |        [Ruby on Rails API]          |  :
:  |                                 |                 |                                     |  :
:  | Interfaz gráfica en Chromium y  |    WebSocket    | Implementa Clean Architecture:      |  :
:  | cliente de socket en Python     |<===============>| Entidades, Casos de Uso y canales   |  :
:  +---------------------------------+    (TCP:3000)   +-------------------------------------+  :
:                                                                 |                             :
:                                                                 | Protocolo Redis             :
:                                                                 | (TCP:6379)                  :
:                                                                 v                             :
:                                                      +-------------------------------------+  :
:                                                      |       BASE DE DATOS EN MEMORIA      |  :
:                                                      |             [Redis 7.x]             |  :
:                                                      |                                     |  :
:                                                      | Conteos O(1), Sets de votantes      |  :
:                                                      | y mensajería interna Pub/Sub        |  :
:                                                      +-------------------------------------+  :
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
```

---

### 3.5. Diagrama Dinámico (Secuencia del Flujo Principal: Emisión y Sincronización de Voto)

#### Objetivo del Diagrama
Explicar el paso a paso cronológico y técnico cuando un usuario emite un voto, demostrando cómo se respetan las fronteras de Clean Architecture, cómo se persiste en Redis y cómo se actualizan todas las pantallas en vivo.

#### Columnas / Líneas de Vida a Dibujar (de izquierda a derecha)
1.  `Delegado` (Actor humano)
2.  `UI (Vista Web)` (HTML/CSS dentro de Chromium)
3.  `Python Local` (main.py de Eel)
4.  `Rails WebSocket` (VotingChannel de ActionCable)
5.  `Caso de Uso` (Core: RegisterVoteUseCase)
6.  `Repositorio` (Infrastructure: RedisVoteRepository)
7.  `Redis Server` (Motor de Base de Datos)
8.  `Otros Clientes` (Terminales de otros delegados conectados)

#### Paso a Paso Lógico Cronológico (10 Pasos)
1.  **Paso 1:** El `Delegado` hace clic en la opción "A Favor" en su pantalla.
2.  **Paso 2:** La `UI` envía una llamada IPC local a `Python Local` ejecutando `submit_vote(poll_id, option_id)`.
3.  **Paso 3:** `Python Local` serializa el voto en un mensaje JSON y lo transmite por el WebSocket persistente hacia `Rails WebSocket`.
4.  **Paso 4 (Frontera Clean Architecture):** `Rails WebSocket` desempaqueta los datos, valida tipos básicos y ejecuta el `Caso de Uso` invocando `execute(VoteDTO)`.
5.  **Paso 5:** El `Caso de Uso` solicita al `Repositorio` verificar y persistir el voto: `record_vote(...)`.
6.  **Paso 6 (Validación de Unicidad Atómica):** El `Repositorio` ejecuta la instrucción `SADD poll:1:voters "usr_123"` en `Redis Server`.
    *   *Bifurcación de Error:* Si Redis retorna `0`, el votante ya había participado. Se detiene el flujo, el caso de uso devuelve un fallo y Rails le envía un mensaje de error únicamente al terminal emisor.
7.  **Paso 7 (Conteo Atómico Exitoso):** Si Redis retorna `1`, el `Repositorio` ejecuta inmediatamente `HINCRBY poll:1:options "opt_A" 1`. Redis incrementa el valor en RAM en tiempo O(1) y retorna el nuevo total consolidado.
8.  **Paso 8:** El `Repositorio` y el `Caso de Uso` retornan una entidad de éxito a `Rails WebSocket`.
9.  **Paso 9 (Emisión Reactiva):** `Rails WebSocket` publica los nuevos resultados a través de ActionCable broadcast.
10. **Paso 10 (Push WebSocket):** El servidor Rails empuja simultáneamente el payload `{event: 'results_updated', totals: {...}}` a `Python Local` del votante y a los `Otros Clientes` conectados. Cada terminal actualiza sus barras y gráficos de inmediato.

#### Esquema Visual Textual para Dibujar
```text
Delegado      UI (Web)     Python      Rails (Cable)    Caso de Uso     Repositorio        Redis       Otros Clientes
   |             |            |              |               |               |               |               |
   |-- 1. Clic ->|            |              |               |               |               |               |
   |   "A Favor" |-- 2. IPC ->|              |               |               |               |               |
   |             |            |-- 3. WS JSON>|               |               |               |               |
   |             |            |              |-- 4. execute->|               |               |               |
   |             |            |              |               |-- 5. record ->|               |               |
   |             |            |              |               |               |-- 6. SADD --->|               |
   |             |            |              |               |               |   (Verificar) |               |
   |             |            |              |               |               |-- 7. HINCRBY->|               |
   |             |            |              |               |               |   (Incremento)|               |
   |             |            |              |               |<-- 8. Éxito --|               |               |
   |             |            |              |<-- Resultado -|               |               |               |
   |             |            |<-- 10. Push -|-- 9. Broadcast ActionCable ------------------>|               |
   |             |            |   WebSocket  |                                               |-- 10. Push -->|
   |             |<-- Actualiz|              |                                               |   WebSocket   |
   |<-- Gráfica -|            |              |                                               |               |
```

---

### 3.6. Diagrama de Despliegue (C4 Deployment)

#### Objetivo del Diagrama
Demostrar el cumplimiento de la directriz obligatoria de uso de contenedores (Docker o Podman), mostrando cómo se aíslan los servicios de backend y base de datos, y cómo se ejecutan frente a la aplicación de escritorio.

#### Paso a Paso Lógico para Dibujarlo a Mano
1.  **Dibujar el Nodo de Hardware Principal:** Un rectángulo exterior grande titulado `Estación de Trabajo / Computadora Host (Windows 11 / Linux / macOS)`.
2.  **Dibujar el espacio del Sistema Operativo Host:** Dentro de la computadora, dibuja:
    *   Una caja para el `Proceso Local de Escritorio`: Contiene `Electron + Python (Eel)`.
    *   Una caja grande para el `Motor de Contenedores (Docker Engine / Podman)`.
3.  **Dibujar los Contenedores dentro de Docker:**
    *   *Contenedor 1 (Backend):* Rectángulo titulado `Contenedor Rails Backend`. Imagen base `Ruby 3.2-alpine`. Ejecuta el servidor Puma en el puerto interno `3000`. Mapeo de puertos hacia el host: `3000:3000`.
    *   *Contenedor 2 (Persistencia):* Rectángulo titulado `Contenedor Redis Store`. Imagen base `redis:7-alpine`. Ejecuta en el puerto interno `6379`. Mapeo de puertos hacia el host: `6379:6379`. Cuenta con un volumen persistente `redis_data` montado en `/data`.
    *   *Red Virtual Docker:* Dibuja una línea envolvente titulada `Red Docker Interna (bridge)`, que conecta directamente a Rails con Redis mediante el nombre de host `redis`.
4.  **Trazar la conexión de red externa:**
    *   Flecha desde el `Proceso Local de Escritorio` (Host OS) hacia el `Contenedor Rails Backend` a través de la interfaz de red local `ws://127.0.0.1:3000/cable`.

#### Esquema Visual Textual para Dibujar
```text
+-----------------------------------------------------------------------------------------------+
|                      ESTACIÓN DE TRABAJO (COMPUTADORA HOST / SISTEMA OPERATIVO)               |
|                                                                                               |
|  +------------------------------------+                                                       |
|  |     PROCESO LOCAL DE ESCRITORIO    |                                                       |
|  |       [Electron + Python (Eel)]    |                                                       |
|  +------------------------------------+                                                       |
|                    |                                                                          |
|                    | WebSocket (TCP:3000)                                                     |
|                    v                                                                          |
|  +-----------------------------------------------------------------------------------------+  |
|  |                                  MOTOR DOCKER / PODMAN                                  |  |
|  |                                                                                         |  |
|  |  +---------------------------------------+       +-----------------------------------+  |  |
|  |  |       CONTENEDOR RAILS BACKEND        |       |      CONTENEDOR REDIS STORE       |  |  |
|  |  |           [Ruby 3.2-alpine]           |       |         [redis:7-alpine]          |  |  |
|  |  |                                       |       |                                   |  |  |
|  |  | Servidor Puma expuesto en puerto 3000 |=====> | Motor de datos en puerto 6379     |  |  |
|  |  | (API REST y ActionCable WebSocket)    |       | Volumen montado: redis_data       |  |  |
|  |  +---------------------------------------+       +-----------------------------------+  |  |
|  |                      Red Interna Docker (bridge): decisionroom_network                  |  |
|  +-----------------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------------+
```

---

## 4. Implementación y Protocolo de Integración

### 4.1. Solución Técnica al Protocolo ActionCable en Python

Para garantizar la interoperabilidad fluida entre Python y Rails ActionCable sin depender de librerías de terceros obsoletas, el cliente Python implementa de forma directa y limpia el subprotocolo estándar de ActionCable mediante la librería oficial `websockets`:

```python
# main.py - Fragmento esencial del cliente WebSocket en Python
import asyncio
import json
import websockets
import eel

WS_URL = "ws://127.0.0.1:3000/cable"
CHANNEL_IDENTIFIER = json.dumps({"channel": "VotingChannel"})

async def connect_to_rails():
    async with websockets.connect(WS_URL) as ws:
        # 1. Handshake y suscripción formal al canal de votación
        welcome_msg = await ws.recv()
        subscribe_cmd = {
            "command": "subscribe",
            "identifier": CHANNEL_IDENTIFIER
        }
        await ws.send(json.dumps(subscribe_cmd))

        # 2. Bucle reactivo de escucha de eventos
        while True:
            raw_msg = await ws.recv()
            payload = json.loads(raw_msg)
            
            # Responder o tolerar pings de salud del servidor
            if payload.get("type") == "ping":
                continue
            
            # Recibir actualizaciones de escrutinio empujadas por Rails
            if "message" in payload:
                event_data = payload["message"]
                if event_data.get("event") == "results_updated":
                    # Actualizar las barras visuales en la interfaz HTML vía Eel
                    eel.update_poll_display(event_data["totals"])()

@eel.expose
def send_vote_to_backend(poll_id, option_id, voter_id):
    # Enviar acción de voto hacia el servidor Rails
    action_payload = {
        "command": "message",
        "identifier": CHANNEL_IDENTIFIER,
        "data": json.dumps({
            "action": "cast_vote",
            "poll_id": poll_id,
            "option_id": option_id,
            "fingerprint": voter_id
        })
    }
    asyncio.run(send_socket_message(action_payload))
```

### 4.2. Caso de Uso en Ruby: `RegisterVote`

Implementación pura de la lógica de negocio desacoplada de controladores web y de ActiveRecord:

```ruby
# app/core/use_cases/register_vote.rb
module Core
  module UseCases
    class RegisterVote
      def initialize(vote_repository:, broadcaster:)
        @repository = vote_repository
        @broadcaster = broadcaster
      end

      def execute(poll_id:, option_id:, voter_fingerprint:)
        # 1. Regla de Negocio: Validar estado de la votación
        poll = @repository.find_poll(poll_id)
        raise StandardError, "La votación no existe o está cerrada" unless poll&.is_open?

        # 2. Regla de Negocio: Validar que no haya votado previamente
        already_voted = @repository.voter_participated?(poll_id, voter_fingerprint)
        raise StandardError, "El usuario ya emitió su voto en esta sesión" if already_voted

        # 3. Persistir atómicamente el voto en Redis
        updated_totals = @repository.record_vote(
          poll_id: poll_id,
          option_id: option_id,
          voter_fingerprint: voter_fingerprint
        )

        # 4. Notificar a los observadores suscritos mediante el mecanismo de emisión
        @broadcaster.broadcast_results(poll_id, updated_totals)

        { success: true, totals: updated_totals }
      end
    end
  end
end
```

---

## 5. Lecciones Aprendidas

1.  **Balance entre Purismo Arquitectónico y Agilidad:**  
    Implementar Clean Architecture en un stack como Ruby on Rails (pensado originalmente para convención MVC y ActiveRecord acoplado) exige un esfuerzo mental inicial considerable para no ceder ante la tentación de mezclar infraestructura con el dominio. Sin embargo, una vez trazadas las fronteras y los repositorios, la facilidad para probar reglas de negocio unitariamente sin base de datos es incomparable.
2.  **Sistemas Distribuidos Heterogéneos:**  
    La integración entre lenguajes dispares (Python en la UI de escritorio y Ruby en el servidor) a través de WebSockets refuerza la importancia de formalizar esquemas de mensajes claros (JSON DTOs). Tratar al backend estrictamente como un proveedor de servicios desacoplado evita dependencias ocultas y facilita el mantenimiento.
3.  **Potencia y Disciplina con Redis:**  
    Redis demuestra ser insuperable para sistemas de conteo y concurrencia en tiempo real gracias a sus operaciones atómicas (`HINCRBY`, `SADD`). No obstante, requiere que el equipo de arquitectura diseñe manualmente los esquemas de indexación y claves, una responsabilidad que los ORMs tradicionales suelen ocultar.
4.  **Simplicidad del Modelo Funcional:**  
    Al concentrar el sistema en una solución de terminales de escritorio (DecisionRoom) en lugar de intentar abarcar clientes móviles mixtos no autorizados, el alcance se tornó completamente coherente, 100% fiel a las restricciones del profesor y técnicamente viable para una sustentación impecable.
