# REQUISITOS TALLER: Presentación 1 - Exploración de Estilos Arquitectónicos y Stack Tecnológico

Documento de control y seguimiento de requisitos para el Grupo 3 (G3). Permite marcar con una cruz [x] cada ítem a medida que se completa su desarrollo, documentación e implementación.

---

## 1. Información General y Asignación del Grupo

*   Asignatura: Arquitectura de Software
*   Actividad: Taller 1 / Presentación 1
*   Grupo: Grupo 3 (G3)
*   Estilo Arquitectónico Asignado: Clean Architecture (Arquitectura Limpia)
*   Stack Tecnológico Obligatorio:
    *   Frontend: Electron + Python (Eel)
    *   Backend: Ruby on Rails (Modo API desacoplado)
    *   Persistencia: Redis (In-Memory Data Store)
    *   Protocolo de Integración: WebSockets (Bidireccional en tiempo real)
    *   Contenerización: Docker / Docker Compose

---

## 2. Checklist de Requisitos y Entregables

### Fase 1: Investigación del Estilo y Stack

#### 1.1. Estilo Arquitectónico (Clean Architecture)
- [x] Definición clara (qué es y qué no es).
- [x] Clasificación del estilo (estructural, separación de intereses, puertos y adaptadores).
- [x] Características principales (independencia de frameworks, UI, DB, alta testabilidad).
- [x] Historia y evolución (Uncle Bob 2012, Hexagonal 2005, Onion 2008).
- [x] Ventajas y desventajas.
- [x] Problemas comunes que se presentan y soluciones/patrones (fuga de infraestructura -> DTOs; acoplamiento -> Inyección de Dependencias).
- [x] Identificar patrones aplicables y cuándo usarlos (Patrón Repositorio, Patrón Caso de Uso/Interactor).
- [x] Casos de uso (cuándo usarlo y cuándo no).
- [x] Casos de aplicación en la industria real (FinTech: Nubank, Revolut, N26).

#### 1.2. Tecnologías del Stack Asignado
- [x] Frontend: Electron + Python (Eel)
  - [x] Definición clara (qué es y qué no es).
  - [x] Características principales.
  - [x] Historia y evolución.
  - [x] Ventajas y desventajas.
  - [x] Casos de uso (cuándo sí y cuándo no).
  - [x] Casos de aplicación en la industria.
- [x] Backend: Ruby on Rails (Modo API)
  - [x] Definición clara (qué es y qué no es).
  - [x] Características principales.
  - [x] Historia y evolución.
  - [x] Ventajas y desventajas.
  - [x] Casos de uso (cuándo sí y cuándo no).
  - [x] Casos de aplicación en la industria.
- [x] Persistencia: Redis (In-Memory Engine)
  - [x] Definición clara (qué es y qué no es).
  - [x] Características principales.
  - [x] Historia y evolución.
  - [x] Ventajas y desventajas.
  - [x] Casos de uso (cuándo sí y cuándo no).
  - [x] Casos de aplicación en la industria.
- [x] Protocolo de Integración: WebSockets
  - [x] Definición clara (qué es y qué no es).
  - [x] Características principales.
  - [x] Historia y evolución.
  - [x] Ventajas y desventajas.
  - [x] Casos de uso (cuándo sí y cuándo no).
  - [x] Casos de aplicación en la industria.

#### 1.3. Relación entre Estilo, Tecnologías y Mercado
- [x] Relación entre el estilo arquitectónico y las tecnologías seleccionadas.
- [x] Análisis de qué tan común es el stack asignado (relación entre tecnologías en el mercado).
- [x] Comandos de creación, estructura de archivos y manejo de variables de entorno (.env).

---

### Fase 2: Análisis Arquitectónico (Matrices Obligatorias)

- [x] Matriz 1: Atributos de Calidad vs Estilo (Mantenibilidad, Testabilidad, Modificabilidad, Rendimiento, Simplicidad).
- [x] Matriz 2: Principios vs Estilo
  - [x] SOLID (SRP, OCP, LSP, ISP, DIP).
  - [x] KISS (Keep It Simple, Stupid).
  - [x] DRY (Don't Repeat Yourself).
  - [x] YAGNI (You Aren't Gonna Need It).
  - [x] PoLA (Principle of Least Astonishment).
  - [x] Ley de Demeter.
  - [x] Prevención de antipatrones STUPID.
  - [x] Composición sobre Herencia.
- [x] Matriz 3: Tácticas vs Estilo y Stack (Justificación formal de un ADR para Concurrencia y Rendimiento en tiempo real).
- [x] Matriz 4: Mercado Laboral vs Estilo y Stack (Demanda actual, proyección a 5 años, salarios anuales y mensuales en USD citando fuentes formales como StackOverflow 2024, GitHub y Hired).

---

### Fase 3: Diseño del Sistema (Modelo C4 y Modelo de Datos)

- [x] Modelo de Datos formal con mínimo 3 entidades de negocio interrelacionadas (`POLL`, `OPTION`, `VOTE`).
- [x] Mapeo de persistencia de las entidades en estructuras de datos de Redis (Hashes y Sets con operaciones O(1)).
- [x] Diagrama de Alto Nivel (HLD) con sus bloques y protocolos definidos.
- [x] Diagrama de Contexto (C4 Nivel 1) con actores y delimitación del sistema.
- [x] Diagrama de Contenedores (C4 Nivel 2) con contenedores, tecnologías y protocolos TCP/puertos.
- [x] Diagrama Dinámico (Flujo Principal de Secuencia end-to-end de 10 pasos con bifurcaciones de error y éxito).
- [x] Diagrama de Despliegue (C4 Deployment) con Host OS, Docker Engine, Contenedores y puertos.
- [x] Guía y estructura lógica paso a paso para dibujar todos los diagramas a mano o en diapositivas.

---

### Fase 4: Implementación Práctica del Caso de Uso

#### 4.1. Configuración de Entornos y Contenedores (Obligatorio Docker / Podman)
- [x] Archivo `Dockerfile` para el backend Ruby on Rails (Ruby 3.2-alpine).
- [x] Archivo `docker-compose.yml` para orquestar Backend y Redis.
- [x] Contenedor Redis oficial levantando en puerto 6379 con volumen de persistencia.
- [x] Configuración del pool de conexión a Redis en Rails sin ActiveRecord (`--skip-active-record`).

#### 4.2. Backend: Clean Architecture en Ruby on Rails
- [x] Crear estructura de carpetas: `app/core/entities`, `app/core/use_cases`, `app/infrastructure/repositories`.
- [x] Implementar Entidades puras de Ruby (POROs): `Poll`, `Option`, `Vote`.
- [x] Implementar Caso de Uso principal: `RegisterVote` con validación de encuesta abierta y control de votante único.
- [x] Implementar Adaptador de Repositorio sobre Redis (`RedisVoteRepository`) con operaciones atómicas (`HINCRBY`, `SADD`).
- [x] Implementar Canal de WebSocket (`VotingChannel`) para recibir la acción `cast_vote` y emitir el broadcast a clientes.
- [x] Manejo de errores y respuestas estructuradas (voto duplicado, opción inválida, sesión cerrada).

#### 4.3. Frontend: Aplicación de Escritorio con Electron + Python (Eel)
- [x] Estructura del proyecto: `main.py`, carpeta `web/` con `index.html`, `styles.css` y `app.js`.
- [x] Interfaz gráfica con listado de opciones de voto y barras de resultados en tiempo real.
- [x] Integración en `main.py` de cliente WebSocket con la librería `websockets` para suscribirse a ActionCable.
- [x] Recepción de eventos push del servidor y actualización reactiva de la interfaz mediante `@eel.expose`.
- [x] Envío de voto desde la UI hacia Python y retransmisión por WebSocket al backend.
- [x] Empaquetado ejecutable de la aplicación con PyInstaller / Eel.

#### 4.4. Pruebas y Validación del Flujo End-to-End
- [x] Probar emisión de voto exitoso desde una instancia de la aplicación de escritorio.
- [x] Abrir dos o más instancias de la app de escritorio y verificar sincronización simultánea de resultados en vivo.
- [x] Probar validación de error al intentar votar dos veces con el mismo identificador.
- [x] Verificar persistencia real de datos consultando Redis directamente con `redis-cli`.

---

### Fase 5: Entregables Finales y Repositorio Git

#### 5.1. Repositorio Git Público
- [ ] Repositorio creado en GitHub con visibilidad pública.
- [ ] Código fuente completo y organizado (Backend, Frontend Desktop, Dockerfiles).
- [ ] Archivo `.gitignore` adecuado para evitar subir dependencias locales (`vendor/`, `venv/`, `__pycache__`, `.env`).
- [ ] Creación de TAG de Git (ej. `v1.0.0` o `entrega-taller1`).
- [ ] Creación del Release formal en GitHub asociado al TAG.

#### 5.2. Documento Técnico
- [x] Sección 1: Investigación completa del estilo y cada tecnología del stack.
- [x] Sección 2: Matrices de análisis arquitectónico (Atributos, Principios, Tácticas/ADR, Mercado laboral).
- [x] Sección 3: Diseño y modelado arquitectónico con guía paso a paso de diagramas y modelo de datos.
- [x] Sección 4: Guía técnica de implementación y fragmentos de código desacoplado.
- [x] Sección 5: Lecciones aprendidas documentadas.

#### 5.3. Archivo README.md
- [x] Descripción clara del sistema (DecisionRoom G3).
- [x] Listado de tecnologías usadas y roles.
- [x] Pasos detallados y reproducibles para el despliegue con Docker Compose y ejecución del cliente Python.
- [x] Enlace directo al documento técnico.

#### 5.4. Presentación Oral e Infografías
- [ ] Diapositivas preparadas con estructura fluida y paleta de colores sobria.
- [ ] Diagramas arquitectónicos dibujados (Modelo de datos, HLD, C4 Nivel 1 Contexto, C4 Nivel 2 Contenedores, Diagrama Dinámico de Secuencia, C4 Deployment).
- [ ] Demostración en vivo preparada (Docker levantado y dos ventanas de la app de escritorio listas para votar y mostrar actualización en tiempo real).
- [ ] Explicación clara de las decisiones técnicas y justificación del estilo Clean Architecture frente a las limitaciones de KISS/YAGNI.
