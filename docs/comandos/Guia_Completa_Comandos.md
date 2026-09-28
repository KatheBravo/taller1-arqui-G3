# Guía Completa de Comandos: Despliegue, Pruebas y Operación
## DecisionRoom G3 - Sistema de Votación en Tiempo Real

Este manual recopila todos los comandos necesarios para desplegar, inspeccionar, operar y probar el sistema de extremo a extremo, estructurados en secuencias lógicas reproducibles.

---

## 1. Prerrequisitos del Entorno

Asegurarse de contar con las siguientes herramientas instaladas en la estación de trabajo:
*   Docker Desktop o Podman (con soporte para Docker Compose).
*   Python 3.10 o superior (para ejecutar el cliente de escritorio y la suite de pruebas).
*   Git (para clonación y gestión de versiones).

---

## 2. Comandos de Infraestructura (Docker Compose)

Todos los comandos de esta sección deben ejecutarse desde la raíz del repositorio (`taller1-arqui-G3/`).

### 2.1. Compilación y Arranque Inicial
Descarga las imágenes oficiales de Alpine, compila el backend de Rails e inicia los servicios:
```bash
docker compose up --build
```
*Tip para ejecución en segundo plano (Daemon mode):*
```bash
docker compose up -d --build
```

### 2.2. Verificación de Estado de los Contenedores
Comprueba que los dos contenedores estén en estado activo (`Up`):
```bash
docker compose ps
```
Salida esperada:
```text
NAME                   IMAGE               COMMAND                  SERVICE   STATUS   PORTS
decisionroom_backend   backend-backend     "bundle exec puma -C…"   backend   Up       0.0.0.0:3000->3000/tcp
decisionroom_redis     redis:7-alpine      "docker-entrypoint.s…"   redis     Up       0.0.0.0:6379->6379/tcp
```

### 2.3. Monitoreo de Registros en Vivo (Logs)
Permite observar en tiempo real la conexión de sockets y comandos de Puma/Rails:
```bash
docker compose logs -f backend
```
Para ver los registros de Redis:
```bash
docker compose logs -f redis
```

### 2.4. Comprobación Rápida de Salud (Healthcheck)
Prueba que el servidor Rails esté respondiendo peticiones HTTP en el puerto 3000:
```bash
curl http://localhost:3000/health
```
En PowerShell:
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:3000/health"
```
Respuesta esperada: `{"status":"ok"}`

### 2.5. Detención de Contenedores
Para detener los servicios conservando el volumen de datos de Redis:
```bash
docker compose down
```
Para detener y eliminar completamente volúmenes (reinicio desde cero absoluto):
```bash
docker compose down -v
```

---

## 3. Comandos de Inspección Directa en Redis (`redis-cli`)

Permite auditar directamente la memoria RAM del motor de base de datos para verificar las estructuras generadas por Clean Architecture.

### 3.1. Acceder a la Consola Interactiva de Redis dentro del Contenedor
```bash
docker exec -it decisionroom_redis redis-cli
```

### 3.2. Comandos de Auditoría dentro de `redis-cli`

*   **Verificar metadatos de la votación:**
    ```text
    HGETALL poll:1
    ```
    Muestra: `id`, `title`, `description`, `status` y `created_at`.

*   **Verificar conteos consolidados de votos por opción (Hash):**
    ```text
    HGETALL poll:1:options
    ```
    Muestra:
    ```text
    1) "opt_A"
    2) "3"
    3) "opt_B"
    4) "1"
    5) "opt_C"
    6) "0"
    ```

*   **Verificar el conjunto de votantes únicos registrados (Set):**
    ```text
    SMEMBERS poll:1:voters
    ```
    Muestra la lista de huellas/tokens únicos de las terminales que ya votaron.

*   **Comprobar si un votante específico ya participó ($O(1)$):**
    ```text
    SISMEMBER poll:1:voters "terminal_mesa_1"
    ```
    Retorna `1` si ya votó, o `0` si aún no ha votado.

*   **Monitorear en vivo cada instrucción recibida en Redis (Streaming de comandos):**
    ```text
    MONITOR
    ```
    *(Presionar Ctrl+C para salir del monitor).*

*   **Salir de la consola interactiva:**
    ```text
    exit
    ```

---

## 4. Comandos del Frontend Desktop (Electron + Python)

### 4.1. Instalación de Dependencias del Cliente
En una terminal nueva, navega a la carpeta del frontend y crea un entorno virtual:
```bash
cd frontend_desktop

# En Windows:
python -m venv venv
venv\Scripts\activate

# En Linux / macOS:
# python3 -m venv venv
# source venv/bin/activate

pip install -r requirements.txt
```

### 4.2. Ejecutar la Aplicación de Escritorio
Inicia la ventana gráfica con conexión WebSocket automática hacia Rails:
```bash
python main.py
```

### 4.3. Simular Múltiples Terminales Concurrentes en la Misma Computadora
Para la sustentación en clase, se pueden abrir dos o más terminales simultáneas con identificadores distintos para demostrar la sincronización reactiva en vivo:

**Terminal 1 (Participante Mesa A):**
En una consola de PowerShell:
```powershell
$env:CLIENT_NODE_ID="terminal_mesa_A"
python main.py
```

**Terminal 2 (Participante Mesa B):**
En una segunda consola de PowerShell:
```powershell
$env:CLIENT_NODE_ID="terminal_mesa_B"
python main.py
```

*Prueba visible:* Al emitir un voto en la Terminal 1, la barra de progreso de la Terminal 2 se incrementará de forma automática en milisegundos a través del WebSocket push sin requerir intervención del usuario.

### 4.4. Generación del Ejecutable Independiente (PyInstaller Standalone)
Compila la aplicación en un archivo `.exe` único que no requiere Python instalado en la máquina final:
```bash
# Ejecutar directamente el script por lotes:
build_executable.bat

# O mediante comando manual:
python -m eel main.py web --onefile --noconsole --name "DecisionRoom_G3"
```
El archivo final se genera en: `frontend_desktop/dist/DecisionRoom_G3.exe`.

---

## 5. Comandos de Pruebas Automatizadas (End-to-End)

Con Docker Compose activo en segundo plano, ejecutar las siguientes suites de prueba:

### 5.1. Suite Automatizada End-to-End en Python (WebSockets + ActionCable)
Verifica el ciclo completo: handshake, suscripción, emisión de voto, rechazo de voto duplicado, voto concurrente y reinicio de sesión.
```bash
python tests/test_e2e_flow.py
```
Salida esperada:
```text
================================================================
 DecisionRoom G3: Suite de Pruebas de Flujo End-to-End
================================================================
[TEST 1] Verificando salud del servidor Rails (/health)...
 -> PASS: Servidor Rails activo y respondiendo 200 OK.

[TEST 2] Estableciendo conexion WebSocket y handshake con ActionCable...
 -> PASS: Handshake 'welcome' recibido de ActionCable.
 -> PASS: Suscripcion confirmada a 'VotingChannel'.
 -> PASS: Estado inicial recibido: 'Aprobacion del Presupuesto de Infraestructura 2026'

[TEST 3] Emitiendo voto valido (Votante: voter_test_123, Opcion: 'opt_A')...
 -> PASS: Evento 'vote_accepted' confirmado.
 -> PASS: Evento 'results_updated' recibido en tiempo real. Totales: {'opt_A': 1, 'opt_B': 0, 'opt_C': 0}

[TEST 4] Probando validacion de voto duplicado...
 -> PASS: Voto duplicado rechazado correctamente por Redis/Dominio: 'El terminal voter_test_123 ya emitio su voto previamente.'

[TEST 5] Emitiendo voto desde segunda terminal independiente...
 -> PASS: Voto de segunda terminal aceptado exitosamente.

[TEST 6] Solicitando reinicio de la votacion (/reset)...
 -> PASS: Votacion reiniciada a cero correctamente: {'opt_A': 0, 'opt_B': 0, 'opt_C': 0}

================================================================
 RESULTADO FINAL: TODOS LOS CASOS DE PRUEBA PASARON EXITOSAMENTE
================================================================
```

### 5.2. Prueba Rápida de Endpoints REST vía PowerShell
Prueba la capa HTTP de soporte sin dependencias externas:
```powershell
powershell -ExecutionPolicy Bypass -File tests/test_api_endpoints.ps1
```

### 5.3. Pruebas Manuales con cURL (Línea de Comandos)

*   **Consultar resultados actuales:**
    ```bash
    curl -X GET http://localhost:3000/polls/1
    ```
*   **Emitir un voto por HTTP:**
    ```bash
    curl -X POST http://localhost:3000/polls/1/vote \
      -H "Content-Type: application/json" \
      -d "{\"option_id\": \"opt_A\", \"fingerprint\": \"curl_voter_1\"}"
    ```
*   **Reiniciar la votación por HTTP:**
    ```bash
    curl -X POST http://localhost:3000/polls/1/reset
    ```

---

## 6. Procedimiento para la Demostración en Vivo en Clase

1.  **5 minutos antes:** Levantar la infraestructura:
    ```bash
    docker compose up -d
    ```
2.  **Verificar salud:** Ejecutar `curl http://localhost:3000/health`.
3.  **Abrir dos terminales de escritorio:**
    *   Una para el expositor proyectando en la pantalla grande.
    *   Otra en una laptop o ventana secundaria para simular un votante.
4.  **Emitir un voto en vivo:** Demostrar cómo se bloquea el botón y se muestra la confirmación verde en el cliente emisor.
5.  **Mostrar actualización reactiva:** Enseñar cómo la pantalla proyectada subió el porcentaje en tiempo real sin recargar.
6.  **Intentar votar de nuevo en la misma ventana:** Demostrar la alerta roja de rechazo por intento de voto duplicado (validación de reglas de negocio en Clean Architecture).
7.  **Presionar "Reiniciar Votación (Demo)":** Demostrar cómo los contadores caen inmediatamente a cero en todas las pantallas simultáneamente.
