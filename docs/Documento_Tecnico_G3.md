# Sistema de Votación Interactiva en Tiempo Real (G3)
## Documento Técnico y de Arquitectura

**Estilo Arquitectónico:** Clean Architecture
**Stack Tecnológico:**
*   **Frontend:** Electron + Python (Eel)
*   **Backend:** Ruby on Rails
*   **Persistencia:** Redis
*   **Integración:** WebSockets (ActionCable)

---

## 1. Investigación del Estilo y Stack

### 1.1. Estilo Arquitectónico: Clean Architecture

**Definición clara (qué es y qué no es)**
Clean Architecture (Arquitectura Limpia) es una filosofía de diseño de software introducida por Robert C. Martin (Uncle Bob) que busca separar las responsabilidades del sistema en capas concéntricas, aislando las reglas de negocio de las dependencias externas (frameworks, bases de datos, UI). 
*Qué no es:* No es un framework, ni una plantilla estricta de código, ni garantiza por sí sola un buen rendimiento; es un conjunto de principios para organizar las dependencias.

**Clasificación del estilo**
Se clasifica como un estilo arquitectónico **estructural y de separación de intereses (Separation of Concerns)**. Pertenece a la familia de arquitecturas de capas y arquitecturas de puertos y adaptadores (Hexagonal, Onion Architecture).

**Características principales**
*   **Independencia de Frameworks:** La arquitectura no depende de la existencia de librerías de terceros.
*   **Testabilidad:** Las reglas de negocio (casos de uso) pueden probarse sin la UI, la base de datos o cualquier otro elemento externo.
*   **Independencia de la UI:** La interfaz de usuario puede cambiar fácilmente (ej. de web a consola) sin alterar el resto del sistema.
*   **Independencia de la Base de Datos:** Puedes cambiar de Oracle o SQL Server a Mongo o Redis; las reglas de negocio no están ligadas a la base de datos.
*   **Independencia de Agentes Externos:** Las reglas de negocio simplemente no saben nada en absoluto del mundo exterior.

**Historia y evolución**
Evolucionó de conceptos previos de separación arquitectónica planteados en los 90s y 2000s, como la Hexagonal Architecture (Alistair Cockburn, 2005) y la Onion Architecture (Jeffrey Palermo, 2008). Robert C. Martin consolidó estas ideas en 2012 bajo el término "Clean Architecture" para unificar las similitudes de estos patrones en un modelo concéntrico único centrado en la "Regla de Dependencia".

**Ventajas y desventajas**
*   **Ventajas:** Alta mantenibilidad, testabilidad profunda, flexibilidad para cambiar tecnologías externas, reducción de deuda técnica a largo plazo, escalabilidad del equipo.
*   **Desventajas:** Alta curva de aprendizaje, sobreingeniería para proyectos pequeños (MVPs), mayor verbosidad (requiere crear muchos archivos, interfaces y DTOs), puede ralentizar el desarrollo inicial.

**Problemas comunes que se presentan y patrones**
*   **Problema:** Fuga de detalles de infraestructura hacia el dominio (ej. usar objetos de la BD en las vistas).
    *   **Patrón:** Data Transfer Objects (DTOs) y Mapeadores.
*   **Problema:** Acoplamiento directo a la base de datos.
    *   **Patrón:** Patrón Repository (Inversión de Dependencias).
*   **Problema:** Instanciación compleja de dependencias a lo largo de las capas.
    *   **Patrón:** Inyección de Dependencias (Dependency Injection Container).

**Identificar patrones aplicables y cuándo usarlos**
*   **Inyección de Dependencias:** Usar siempre para suministrar repositorios y servicios externos a los Casos de Uso.
*   **Patrón Repositorio:** Usar para abstraer las operaciones de Redis, permitiendo que la capa de dominio defina la interfaz y la capa de infraestructura la implemente.
*   **Patrón Observer / PubSub:** Aplicable para manejar la integración con WebSockets (ActionCable) y notificar en tiempo real cuando cambia el estado.

**Casos de uso (cuándo usarlo y cuándo no)**
*   **Cuándo usarlo:** Sistemas Enterprise, proyectos a largo plazo con lógicas de negocio complejas, sistemas que prevén cambios de tecnología o plataformas en el futuro, o proyectos con grandes equipos de desarrollo.
*   **Cuándo no usarlo:** Proyectos cortos o MVPs, pruebas de concepto, aplicaciones CRUD muy simples donde un patrón MVC tradicional en un framework maduro (como el estándar de Rails) es suficiente y más rápido.

**Casos de aplicación (ejemplos reales en la industria)**
Empresas como Uber, Netflix y N26 aplican variantes de Clean Architecture (y arquitecturas hexagonales) en sus microservicios de backend para aislar su compleja lógica de enrutamiento, pagos o streaming, permitiéndoles migrar bases de datos (ej. de SQL a NoSQL o Redis) sin reescribir todo el dominio de la aplicación.

### 1.2. Tecnologías del Stack Asignado

#### Frontend: Electron + Python (Eel)
*   **Definición:** Electron es un framework para crear aplicaciones de escritorio nativas usando tecnologías web (HTML, CSS, JS). Eel es una librería de Python que levanta interfaces de usuario usando Chromium/Electron, permitiendo que la lógica resida completamente en Python en lugar de JavaScript.
*   **Características principales:** Multiplataforma (Windows, Mac, Linux), acceso a APIs nativas del sistema operativo, puente bidireccional entre UI y backend (en este caso, Python).
*   **Historia y evolución:** Electron fue creado por GitHub en 2013 para construir el editor Atom. Eel surgió como una alternativa moderna para desarrolladores Python que deseaban interfaces gráficas web sin lidiar con frameworks anticuados como Tkinter.
*   **Ventajas y desventajas:** 
    *   *Ventajas:* Reutilización de conocimiento web, despliegue en múltiples OS, integración profunda con el ecosistema de IA/Datos de Python.
    *   *Desventajas:* Alto consumo de memoria RAM (levanta un navegador completo), peso del ejecutable.
*   **Casos de uso:** Herramientas internas, dashboards de datos, IDEs (VS Code usa Electron). No usar para apps de rendimiento crítico (ej. videojuegos 3D intensivos).
*   **Casos de aplicación:** Slack, Discord, WhatsApp Desktop (Electron).
*   **Relación Electron + Python (Eel):** Permite aislar completamente la vista (HTML/CSS) de la lógica de negocio (Python), cumpliendo con Clean Architecture de manera estricta al evitar la mezcla de código JS en las vistas.

#### Backend: Ruby on Rails (Ruby)
*   **Definición:** Un framework de aplicaciones web del lado del servidor escrito en Ruby bajo el paradigma MVC (Modelo-Vista-Controlador).
*   **Características principales:** Convención sobre Configuración (CoC), Don't Repeat Yourself (DRY), patrón ActiveRecord, y gemas extensibles.
*   **Historia y evolución:** Creado por David Heinemeier Hansson (DHH) en 2003 durante su trabajo en Basecamp. Revolucionó el desarrollo web por su velocidad de prototipado.
*   **Ventajas y desventajas:** 
    *   *Ventajas:* Alta velocidad de desarrollo, comunidad madura, excelente para MVPs.
    *   *Desventajas:* Menor rendimiento en bruto frente a lenguajes compilados, alto acoplamiento a su propio ORM (ActiveRecord) lo que desafía a Clean Architecture.
*   **Casos de uso:** Startups, sistemas e-commerce, APIs RESTful, plataformas SaaS.
*   **Casos de aplicación:** GitHub, Shopify, Airbnb, Twitch.

#### Persistencia: Redis
*   **Definición:** Es un almacén de estructuras de datos en memoria de código abierto, usado como base de datos, caché y message broker.
*   **Características principales:** Almacenamiento clave-valor, altísimo rendimiento (milisegundos), soporte para estructuras de datos complejas (Listas, Sets, Hashes, Pub/Sub).
*   **Historia y evolución:** Creado por Salvatore Sanfilippo en 2009 para mejorar los tiempos de carga de su startup de analíticas web.
*   **Ventajas y desventajas:** 
    *   *Ventajas:* Velocidad extrema, facilidad de uso, escalabilidad.
    *   *Desventajas:* Los datos residen en la RAM (más cara que el disco duro), no es ideal para datos relacionales complejos o grandes volúmenes de datos históricos inactivos.
*   **Casos de uso:** Tableros de posiciones (Leaderboards) en tiempo real, manejo de sesiones, cachés, Pub/Sub.
*   **Casos de aplicación:** Twitter (para armar timelines en tiempo real), StackOverflow, Pinterest.

#### Protocolo de Integración: WebSockets
*   **Definición:** Un protocolo de comunicación que proporciona canales bidireccionales y full-duplex sobre una única conexión TCP de larga duración.
*   **Características principales:** Baja latencia, persistencia de conexión, comunicación orientada a eventos.
*   **Historia y evolución:** Estandarizado en 2011 (RFC 6455) para superar las limitaciones de HTTP (polling constante) al construir aplicaciones web en tiempo real.
*   **Ventajas y desventajas:** 
    *   *Ventajas:* Comunicación instantánea, reduce el tráfico de red (overhead de HTTP).
    *   *Desventajas:* Mayor complejidad de infraestructura (balanceadores de carga deben soportarlo), requiere manejo de caídas y reconexiones.
*   **Casos de uso:** Chats, streaming de datos financieros, juegos multijugador, **sistemas de votación interactiva**.
*   **Casos de aplicación:** Binance (precios en vivo), WhatsApp Web.

### 1.3. Relación entre el estilo y las tecnologías (y nivel de comunión)
*   **¿Qué tan común es el stack?** La combinación específica de **Electron+Python para frontend** y **Rails+Redis para backend** no es tradicional en proyectos estándar, lo cual lo convierte en un ecosistema altamente desacoplado. Rails y Redis sí son inseparables en la industria (Rails usa Redis nativamente para ActionCable/WebSockets y Caché). Por otro lado, aislar la UI en Electron con Python interactuando con un backend remoto mediante WebSockets es un modelo de "Sistemas Distribuidos" interesante.
*   **Relación con Clean Architecture:** Esta separación estricta favorece Clean Architecture. El núcleo de negocio vivirá en Python (aplicación cliente pesada) o en Ruby (servidor), comunicándose a través del puerto definido (WebSockets). Rails, que tiende a estar altamente acoplado, deberá ser refactorizado para separar sus Controladores de los Casos de Uso, limitando a Rails a ser solo un "Framework de Entrega Web" (Delivery Mechanism) y a Redis como un simple "Detalle de Base de Datos".

### 1.4. Frameworks: Comandos, Estructura y Variables de Entorno

*(Nota para la exposición: No nos enfocaremos en Python o Ruby como lenguajes, sino en el uso específico de las herramientas).*

**Backend: Ruby on Rails**
*   **Comandos de creación:** 
    *   `rails new backend_votacion --api` (Crea un proyecto Rails en modo API, omitiendo las vistas HTML tradicionales).
    *   `rails generate controller Votos` (Genera el controlador base).
*   **Estructura de archivos:**
    *   Por convención, Rails usa `app/controllers`, `app/models`, `app/views`. 
    *   *Adaptación Clean Architecture:* Crearemos nuevas carpetas: `app/core/entities` (entidades de negocio puras) y `app/core/use_cases` (lógica de negocio). Rails quedará relegado a `app/controllers` y a `app/infrastructure` para la persistencia.
*   **Manejo de variables de entorno:** Rails utiliza `ENV['REDIS_URL']` o archivos como `.env` (con la gema `dotenv-rails`) y las credenciales encriptadas en `config/credentials.yml.enc` para proteger contraseñas y URLs de la base de datos.

**Frontend: Electron + Python (Eel)**
*   **Comandos de creación:** 
    *   `pip install eel` (Instala la librería).
    *   `python -m eel main.py web --onefile` (Comando para empaquetar y compilar la aplicación en un ejecutable usando PyInstaller, cumpliendo con la necesidad de despliegue).
*   **Estructura de archivos:**
    *   `main.py`: Archivo principal de Python que levanta la ventana, interactúa con el SO y maneja la conexión WebSockets con Rails.
    *   `web/`: Carpeta que contiene `index.html` y `style.css` (sin lógica JS).
*   **Manejo de variables de entorno:** Se utiliza la librería `python-dotenv` cargando un archivo `.env` para almacenar la IP o URL del servidor Rails al cual conectarse vía WebSocket (ej. `WS_SERVER_URL=ws://localhost:3000/cable`).

---

## 2. Análisis Arquitectónico

A continuación se presentan las matrices de análisis para evaluar cómo Clean Architecture y el stack tecnológico seleccionado impactan el desarrollo del sistema de votación.

### 2.1. Matriz de Atributos de Calidad vs Estilo

| Atributo de Calidad | ¿El estilo (Clean) lo soporta o limita? | Justificación |
| :--- | :--- | :--- |
| **Mantenibilidad** | **Lo soporta (Alto)** | Separar el dominio de la infraestructura facilita localizar errores y realizar actualizaciones sin afectar otras capas. |
| **Testabilidad** | **Lo soporta (Alto)** | Los Casos de Uso y Entidades se pueden probar unitariamente al 100% aislando Rails y Redis mediante *Mocks*. |
| **Flexibilidad / Interoperabilidad** | **Lo soporta (Alto)** | Permite cambiar la UI (ej. de web a móvil) o la persistencia (de Redis a PostgreSQL) sin reescribir la lógica de negocio. |
| **Rendimiento (Performance)** | **Lo limita (Leve)** | El paso estricto de datos entre capas (usando DTOs) añade un pequeño *overhead* computacional en comparación con consultas directas acopladas. |
| **Simplicidad (Time to Market)** | **Lo limita (Alto)** | Exige crear muchas clases, interfaces y archivos para operaciones simples, ralentizando la velocidad de desarrollo en fases iniciales. |

### 2.2. Matriz de Análisis de Principios vs Estilo

| Principio | ¿El estilo lo cumple? | Justificación |
| :--- | :--- | :--- |
| **SOLID (SRP, OCP, LSP, ISP, DIP)** | **Sí (Altamente)** | Clean Architecture está construida sobre SOLID. Obliga a separar responsabilidades (SRP), invertir dependencias (DIP) y mantener las entidades cerradas a la modificación de frameworks (OCP). |
| **KISS** (Keep It Simple, Stupid) | **No (Lo rompe)** | Clean Architecture introduce una complejidad accidental (muchas capas, interfaces, DTOs) que va en contra de la filosofía de "mantenerlo simple". |
| **DRY** (Don't Repeat Yourself) | **Parcialmente** | Aunque evita la repetición de lógica de negocio, **obliga a repetir estructuras de datos** (ej. un Modelo de BD, un DTO de red y una Entidad de negocio suelen tener los mismos campos). |
| **YAGNI** (You Aren't Gonna Need It) | **No (Lo rompe)** | A menudo se crean abstracciones (puertos e interfaces) para bases de datos "por si acaso se cambia en el futuro", violando este principio. |
| **PoLA** (Principle of Least Astonishment) | **Sí** | Las reglas estrictas de dependencias hacen que el flujo del código sea predecible. Un desarrollador sabe exactamente dónde buscar la lógica de negocio (Casos de Uso). |
| **Ley de Demeter** | **Sí** | El uso de DTOs y el paso de datos entre fronteras de arquitectura asegura que los objetos solo hablen con sus "amigos cercanos", evitando acoplamiento profundo. |
| **STUPID** (Antipatrones) | **Los previene** | Previene fuertemente el acoplamiento (Tight Coupling) y la intratabilidad (Untestability) gracias a la Inyección de Dependencias. |
| **Composición sobre Herencia** | **Sí** | Los Casos de Uso no heredan de frameworks base (como `ApplicationController`), sino que se componen inyectándoles los Repositorios que necesitan. |

### 2.3. Matriz de Análisis de Tácticas vs Estilo y Stack (Justificación ADR)

*En base a un ADR (Architecture Decision Record) hipotético para garantizar Rendimiento y Escalabilidad.*

| Táctica Arquitectónica | Aplicación en el Estilo (Clean) | Aplicación en el Stack (Rails + Redis) |
| :--- | :--- | :--- |
| **Aumentar la eficiencia computacional** | Limitada (por el overhead de capas y mapeos). | **Excelente:** Redis maneja datos en memoria RAM (O(1)), garantizando operaciones ultrarrápidas. |
| **Introducir concurrencia** | Los casos de uso puramente funcionales son thread-safe si no guardan estado. | **Buena:** Ruby soporta concurrencia con servidores como Puma, y ActionCable maneja miles de hilos de WebSockets. |
| **Mantener copias múltiples (Caché)** | Se puede definir un Puerto (`CacheRepository`) en el dominio. | **Excelente:** Redis es el estándar de facto en la industria para caché. |
| **Desacoplar la comunicación (Eventos)** | Fomentado. Los casos de uso disparan eventos de dominio sin saber quién los escucha. | **Excelente:** Uso del patrón Pub/Sub en Redis y emisión asíncrona mediante ActionCable (WebSockets). |

### 2.4. Matriz de Mercado Laboral vs Estilo y Stack

*Fuentes consultadas: StackOverflow Developer Survey 2024, GitHub Octoverse, LinkedIn Economic Graph.*

| Tecnología / Perfil | Demanda Actual | Proyección (5 años) | Salario Promedio Anual (USD) |
| :--- | :--- | :--- | :--- |
| **Arquitectura Limpia / Hexagonal** | Alta (Perfiles Senior/Staff) | Creciente (Sistemas complejos/Microservicios) | $120,000 - $160,000+ |
| **Python (Backend/IA)** | Masiva (Top 3 mundial) | Muy Alta (Impulsada por IA) | $105,000 - $150,000 |
| **Ruby on Rails** | Nicho Estable (Startups maduras) | Estable (Mantenimiento y nuevas SaaS) | $95,000 - $140,000 |
| **Redis (Especialista en Datos)** | Alta (Infraestructura y Caché) | Alta (Sistemas en Tiempo Real) | $110,000 - $155,000 |
| **Electron / Desktop (Frontend)** | Media/Nicho (Herramientas B2B) | Estable | $80,000 - $130,000 |

*Conclusión del Mercado:* Este stack forma un perfil altamente cotizado de "Ingeniero Full-Stack de Tiempo Real". Aunque Ruby on Rails no es tan masivo como JavaScript, sus desarrolladores Senior figuran entre los mejor pagados por la rentabilidad de las empresas que lo usan.

---

*(Siguiente: Diseño HLD y C4 Model...)*

