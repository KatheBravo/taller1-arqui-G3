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
- [ ] Definición clara (qué es y qué no es).
- [ ] Clasificación del estilo (estructural, separación de intereses, puertos y adaptadores).
- [ ] Características principales (independencia de frameworks, UI, DB, alta testabilidad).
- [ ] Historia y evolución (Uncle Bob 2012, Hexagonal 2005, Onion 2008).
- [ ] Ventajas y desventajas.
- [ ] Problemas comunes que se presentan y soluciones/patrones (fuga de infraestructura -> DTOs; acoplamiento -> Inyección de Dependencias).
- [ ] Identificar patrones aplicables y cuándo usarlos (Patrón Repositorio, Patrón Caso de Uso/Interactor).
- [ ] Casos de uso (cuándo usarlo y cuándo no).
- [ ] Casos de aplicación en la industria real (FinTech: Nubank, Revolut, N26).

#### 1.2. Tecnologías del Stack Asignado
- [ ] Frontend: Electron + Python (Eel)
  - [ ] Definición clara (qué es y qué no es).
  - [ ] Características principales.
  - [ ] Historia y evolución.
  - [ ] Ventajas y desventajas.
  - [ ] Casos de uso (cuándo sí y cuándo no).
  - [ ] Casos de aplicación en la industria.
- [ ] Backend: Ruby on Rails (Modo API)
  - [ ] Definición clara (qué es y qué no es).
  - [ ] Características principales.
  - [ ] Historia y evolución.
  - [ ] Ventajas y desventajas.
  - [ ] Casos de uso (cuándo sí y cuándo no).
  - [ ] Casos de aplicación en la industria.
- [ ] Persistencia: Redis (In-Memory Engine)
  - [ ] Definición clara (qué es y qué no es).
  - [ ] Características principales.
  - [ ] Historia y evolución.
  - [ ] Ventajas y desventajas.
  - [ ] Casos de uso (cuándo sí y cuándo no).
  - [ ] Casos de aplicación en la industria.
- [ ] Protocolo de Integración: WebSockets
  - [ ] Definición clara (qué es y qué no es).
  - [ ] Características principales.
  - [ ] Historia y evolución.
  - [ ] Ventajas y desventajas.
  - [ ] Casos de uso (cuándo sí y cuándo no).
  - [ ] Casos de aplicación en la industria.

#### 1.3. Relación entre Estilo, Tecnologías y Mercado
- [ ] Relación entre el estilo arquitectónico y las tecnologías seleccionadas.
- [ ] Análisis de qué tan común es el stack asignado (relación entre tecnologías en el mercado).
- [ ] Comandos de creación, estructura de archivos y manejo de variables de entorno (.env).

---

### Fase 2: Análisis Arquitectónico (Matrices Obligatorias)

- [ ] Matriz 1: Atributos de Calidad vs Estilo (Mantenibilidad, Testabilidad, Modificabilidad, Rendimiento, Simplicidad).
- [ ] Matriz 2: Principios vs Estilo
  - [ ] SOLID (SRP, OCP, LSP, ISP, DIP).
  - [ ] KISS (Keep It Simple, Stupid).
  - [ ] DRY (Don't Repeat Yourself).
  - [ ] YAGNI (You Aren't Gonna Need It).
  - [ ] PoLA (Principle of Least Astonishment).
  - [ ] Ley de Demeter.
  - [ ] Prevención de antipatrones STUPID.
  - [ ] Composición sobre Herencia.
- [ ] Matriz 3: Tácticas vs Estilo y Stack (Justificación formal de un ADR para Concurrencia y Rendimiento en tiempo real).
- [ ] Matriz 4: Mercado Laboral vs Estilo y Stack (Demanda actual, proyección a 5 años, salarios anuales y mensuales en USD citando fuentes formales como StackOverflow 2024, GitHub y Hired).

---

### Fase 3: Diseño del Sistema (Modelo C4 y Modelo de Datos)

- [ ] Modelo de Datos formal con mínimo 3 entidades de negocio interrelacionadas (`POLL`, `OPTION`, `VOTE`).
- [ ] Mapeo de persistencia de las entidades en estructuras de datos de Redis (Hashes y Sets con operaciones O(1)).
- [ ] Diagrama de Alto Nivel (HLD) con sus bloques y protocolos definidos.
- [ ] Diagrama de Contexto (C4 Nivel 1) con actores y delimitación del sistema.
- [ ] Diagrama de Contenedores (C4 Nivel 2) con contenedores, tecnologías y protocolos TCP/puertos.
- [ ] Diagrama Dinámico (Flujo Principal de Secuencia end-to-end de 10 pasos con bifurcaciones de error y éxito).
- [ ] Diagrama de Despliegue (C4 Deployment) con Host OS, Docker Engine, Contenedores y puertos.
- [ ] Guía y estructura lógica paso a paso para dibujar todos los diagramas a mano o en diapositivas.

---

### Fase 4: Implementación Práctica del Caso de Uso

#### 4.1. Configuración de Entornos y Contenedores (Obligatorio Docker / Podman)
- [ ] Archivo `Dockerfile` para el backend Ruby on Rails (Ruby 3.2-alpine).
- [ ] Archivo `docker-compose.yml` para orquestar Backend y Redis.
- [ ] Contenedor Redis oficial levantando en puerto 6379 con volumen de persistencia.
- [ ] Configuración del pool de conexión a Redis en Rails sin ActiveRecord (`--skip-active-record`).

#### 4.2. Backend: Clean Architecture en Ruby on Rails
- [ ] Crear estructura de carpetas: `app/core/entities`, `app/core/use_cases`, `app/infrastructure/repositories`.
- [ ] Implementar Entidades puras de Ruby (POROs): `Poll`, `Option`, `Vote`.
- [ ] Implementar Caso de Uso principal: `RegisterVote` con validación de encuesta abierta y control de votante único.
- [ ] Implementar Adaptador de Repositorio sobre Redis (`RedisVoteRepository`) con operaciones atómicas (`HINCRBY`, `SADD`).
- [ ] Implementar Canal de WebSocket (`VotingChannel`) para recibir la acción `cast_vote` y emitir el broadcast a clientes.
- [ ] Manejo de errores y respuestas estructuradas (voto duplicado, opción inválida, sesión cerrada).

#### 4.3. Frontend: Aplicación de Escritorio con Electron + Python (Eel)
- [ ] Estructura del proyecto: `main.py`, carpeta `web/` con `index.html`, `styles.css` y `app.js`.
- [ ] Interfaz gráfica con listado de opciones de voto y barras de resultados en tiempo real.
- [ ] Integración en `main.py` de cliente WebSocket con la librería `websockets` para suscribirse a ActionCable.
- [ ] Recepción de eventos push del servidor y actualización reactiva de la interfaz mediante `@eel.expose`.
- [ ] Envío de voto desde la UI hacia Python y retransmisión por WebSocket al backend.
- [ ] Empaquetado ejecutable de la aplicación con PyInstaller / Eel.

#### 4.4. Pruebas y Validación del Flujo End-to-End
- [ ] Probar emisión de voto exitoso desde una instancia de la aplicación de escritorio.
- [ ] Abrir dos o más instancias de la app de escritorio y verificar sincronización simultánea de resultados en vivo.
- [ ] Probar validación de error al intentar votar dos veces con el mismo identificador.
- [ ] Verificar persistencia real de datos consultando Redis directamente con `redis-cli`.

---

### Fase 5: Entregables Finales y Repositorio Git

#### 5.1. Repositorio Git Público
- [ ] Repositorio creado en GitHub con visibilidad pública.
- [ ] Código fuente completo y organizado (Backend, Frontend Desktop, Dockerfiles).
- [ ] Archivo `.gitignore` adecuado para evitar subir dependencias locales (`vendor/`, `venv/`, `__pycache__`, `.env`).
- [ ] Creación de TAG de Git (ej. `v1.0.0` o `entrega-taller1`).
- [ ] Creación del Release formal en GitHub asociado al TAG.

#### 5.2. Documento Técnico
- [ ] Sección 1: Investigación completa del estilo y cada tecnología del stack.
- [ ] Sección 2: Matrices de análisis arquitectónico (Atributos, Principios, Tácticas/ADR, Mercado laboral).
- [ ] Sección 3: Diseño y modelado arquitectónico con guía paso a paso de diagramas y modelo de datos.
- [ ] Sección 4: Guía técnica de implementación y fragmentos de código desacoplado.
- [ ] Sección 5: Lecciones aprendidas documentadas.

#### 5.3. Archivo README.md
- [ ] Descripción clara del sistema (DecisionRoom G3).
- [ ] Listado de tecnologías usadas y roles.
- [ ] Pasos detallados y reproducibles para el despliegue con Docker Compose y ejecución del cliente Python.
- [ ] Enlace directo al documento técnico.

#### 5.4. Presentación Oral e Infografías
- [ ] Diapositivas preparadas con estructura fluida y paleta de colores sobria.
- [ ] Diagramas arquitectónicos dibujados (Modelo de datos, HLD, C4 Nivel 1 Contexto, C4 Nivel 2 Contenedores, Diagrama Dinámico de Secuencia, C4 Deployment).
- [ ] Demostración en vivo preparada (Docker levantado y dos ventanas de la app de escritorio listas para votar y mostrar actualización en tiempo real).
- [ ] Explicación clara de las decisiones técnicas y justificación del estilo Clean Architecture frente a las limitaciones de KISS/YAGNI.
