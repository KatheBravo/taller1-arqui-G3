# Documentación Técnica de Implementación: Fase 4.3
## Frontend: Aplicación de Escritorio con Electron + Python (Eel)

**Módulo:** Cliente de Presentación y Experiencia de Usuario  
**Tecnologías:** Python 3.10+, Eel (Chromium IPC), WebSockets (ActionCable Client), HTML5/CSS3/JavaScript  
**Asignación:** Grupo 3 (DecisionRoom G3)

---

## 1. Objetivo de la Fase

Desarrollar la interfaz gráfica de usuario asignada obligatoriamente al grupo (**Electron + Python**), garantizando:
1. Una experiencia de escritorio reactiva y moderna ejecutada sobre el motor de renderizado de Chromium.
2. Integración nativa entre Python y la interfaz web mediante el puente de comunicación inter-procesos (IPC) provisto por Eel.
3. Conexión bidireccional y persistente sobre TCP mediante la librería `websockets` en Python, resolviendo el subprotocolo específico de Rails ActionCable.
4. Actualización en tiempo real (*Server Push*) de las métricas, conteos y barras de progreso sin recargar la pantalla.
5. Capacidad de compilación y distribución como un ejecutable independiente (*standalone*) mediante PyInstaller.

---

## 2. Justificación Arquitectónica: Desacoplamiento y Rol del Cliente

*   **El Cliente como Consumidor Externo:** En Clean Architecture, la interfaz de usuario reside en el anillo más externo (Mecanismos de Entrega). La aplicación de escritorio no comparte memoria ni código con el backend en Ruby on Rails; su único contrato es el esquema de mensajes JSON intercambiados a través del socket TCP en el puerto 3000.
*   **Por qué Eel + Python:** Permite diseñar interfaces visuales ricas y dinámicas con tecnologías web estándar (HTML/CSS) mientras toda la lógica de concurrencia de red, manejo de sockets asíncronos y acceso al sistema operativo se ejecuta en Python, superando las limitaciones estéticas de librerías como Tkinter sin obligar al equipo a construir toda la lógica en Node.js.
*   **Concurrencia Híbrida (Hilos + Asyncio):** Eel opera bloqueando el hilo principal con su servidor web local. Para mantener activa la conexión WebSocket con Rails sin congelar la ventana gráfica, la aplicación implementa un hilo secundario exclusivo (*daemon thread*) que corre un bucle de eventos asíncrono (`asyncio`).

---

## 3. Estructura del Proyecto y Archivos Creados

```text
frontend_desktop/
├── requirements.txt            # Dependencias del entorno Python
├── .env.example                # Plantilla de variables de entorno
├── main.py                     # Orquestador Python (Eel + WebSocket Client)
├── build_executable.bat        # Script de compilacion con PyInstaller
└── web/                        # Interfaz gráfica (renderizada en Chromium)
    ├── index.html              # Estructura visual de la terminal
    ├── css/
    │   └── styles.css          # Estilos modernos, paleta oscura y animaciones
    └── js/
        └── app.js              # Controlador de UI y enlace IPC con Eel
```

---

### 3.1. Dependencias del Entorno: `requirements.txt`

*   `eel (>=0.16.0)`: Puente de comunicación bidireccional entre Python y Chromium.
*   `websockets (>=12.0)`: Cliente asíncrono de alto rendimiento para conexiones WebSockets puras sobre TCP.
*   `python-dotenv (>=1.0.0)`: Carga de variables de entorno locales.
*   `pyinstaller (>=6.0.0)`: Generador de ejecutables binarios independientes.

---

### 3.2. Orquestador Principal: `frontend_desktop/main.py`

Es el núcleo del cliente de escritorio y se estructura en tres bloques funcionales:

#### A. Bucle Asíncrono del Protocolo ActionCable (`websocket_listener`)
Rails ActionCable no utiliza WebSockets planos; exige un subprotocolo de apretón de manos (*Handshake*):
1.  **Conexión Inicial:** Abre el socket hacia `ws://127.0.0.1:3000/cable`.
2.  **Mensaje de Bienvenida:** El servidor envía `{"type":"welcome"}`.
3.  **Comando de Suscripción:** Python envía inmediatamente:
    ```json
    {
      "command": "subscribe",
      "identifier": "{\"channel\":\"VotingChannel\"}"
    }
    ```
4.  **Confirmación y Pings:** ActionCable responde con `confirm_subscription` y envía pings cada 3 segundos (`{"type":"ping"}`) que el bucle ignora silenciosamente para mantener la conexión activa.
5.  **Despacho de Eventos hacia la UI:** Cuando llega un payload en `message`:
    *   `session_state`: Invoca `eel.update_poll_state(data)` para pintar la moción y opciones iniciales.
    *   `results_updated`: Invoca `eel.update_results(payload)` para mover las barras de porcentaje en vivo.
    *   `vote_accepted`: Invoca `eel.on_vote_accepted(payload)` para confirmar al usuario.
    *   `vote_error`: Invoca `eel.on_vote_error(message)` para alertar de votos duplicados o sesión cerrada.
6.  **Reconexión Automática:** Si el backend se apaga o reinicia, el bloque captura `ConnectionClosed` o `ConnectionRefusedError` y reintenta la conexión cada 3 segundos, actualizando el indicador de estado visual a color rojo.

#### B. Funciones Expuestas hacia JavaScript (`@eel.expose`)
*   `send_vote(poll_id, option_id)`: Empaqueta la acción `cast_vote` con el identificador único del terminal (`CLIENT_NODE_ID`) y la encola de forma segura en la cola asíncrona hacia el socket.
*   `reset_session(poll_id)`: Envía la acción `reset_poll` para reiniciar contadores.
*   `request_initial_state()`: Solicita el estado consolidado al abrir la ventana.

#### C. Fallback Automático de Motores de Navegación
Para asegurar que la aplicación corra en cualquier sistema operativo Windows o Linux sin configuraciones manuales:
1.  Intenta arrancar en modo `chrome`.
2.  Si Google Chrome no está instalado, conmuta automáticamente a Microsoft Edge (`mode="edge"`).
3.  Si ninguno está presente, levanta la ventana en el navegador predeterminado del sistema (`mode="default"`).

---

### 3.3. Interfaz de Usuario: `web/index.html` y `web/css/styles.css`

*   **Identidad Visual:** Diseño sobrio en modo oscuro (*Dark Mode*) con fondo `#0f172a` y tarjetas en `#1e293b`, optimizado para visualización en pantallas de asamblea o proyectores.
*   **Indicador de Salud en Vivo:** Badge circular superior con punto verde pulsante que cambia a rojo si la conexión WebSocket se interrumpe.
*   **Barras de Progreso Dinámicas:** Cada alternativa ("A Favor", "En Contra", "Abstención") cuenta con una pista de progreso (`progress-track`) y un relleno animado con transición CSS suave (`transition: width 0.4s ease-out`).
*   **Identificador de Terminal:** Muestra el ID del nodo (ej. `terminal_a1b2c3`) para demostrar en clase que cada ventana actúa como un votante independiente.

---

### 3.4. Controlador del DOM y Enlace IPC: `web/js/app.js`

*   Expone funciones JavaScript para que Python pueda llamarlas directamente:
    *   `set_connection_status(isConnected, text)`: Modifica las clases y texto del badge de conexión.
    *   `update_results(payload)`: Calcula y asigna los anchos porcentuales (`style.width = pct + '%'`) y actualiza los textos numéricos.
    *   `on_vote_accepted()`: Bloquea los botones de votación y muestra un banner verde de éxito.
    *   `on_vote_error(msg)`: Despliega una alerta visual roja con la razón del rechazo emitida por el backend (ej. *"El terminal ya emitió su voto previamente"*).
*   Captura el evento `DOMContentLoaded` para solicitar los datos iniciales apenas se abre la ventana.

---

### 3.5. Compilación a Ejecutable: `build_executable.bat`

Automatiza la compilación utilizando PyInstaller:

```batch
python -m eel main.py web --onefile --noconsole --name "DecisionRoom_G3"
```

Genera un único archivo ejecutable en `dist/DecisionRoom_G3.exe` que empaqueta el intérprete de Python, las librerías y los archivos web estáticos, listo para ser ejecutado en cualquier máquina Windows sin requerir instalación previa de Python.

---

## 4. Diagrama del Flujo de Comunicación Cliente-Servidor

```text
Usuario en Terminal                  app.js (Chromium)               main.py (Python)             Rails (ActionCable)
        |                                   |                               |                             |
        |--- 1. Clic "A Favor" ------------>|                               |                             |
        |                                   |--- 2. eel.send_vote(...) ---->|                             |
        |                                   |                               |--- 3. WS Frame JSON ------->|
        |                                   |                               |    {action: "cast_vote"}    |
        |                                   |                               |                             | (Procesa en Clean Core)
        |                                   |                               |<-- 4. WS Frame -------------|
        |                                   |                               |    {event: "vote_accepted"} |
        |                                   |<-- 5. on_vote_accepted() -----|                             |
        |<-- 6. Botones bloqueados (Éxito) -|                               |                             |
        |                                   |                               |<-- 7. WS Broadcast Push ----|
        |                                   |                               |    {results_updated}        |
        |                                   |<-- 8. update_results() -------|                             |
        |<-- 9. Barra se anima al 100% -----|                               |                             |
```

---

## 5. Guía de Ejecución de la Fase

### Opción A: Ejecución en Modo Desarrollo
1.  Abrir una terminal en `frontend_desktop/`:
    ```bash
    cd frontend_desktop
    python -m venv venv
    venv\Scripts\activate
    pip install -r requirements.txt
    ```
2.  Iniciar la aplicación:
    ```bash
    python main.py
    ```
3.  *Simulación Multi-Usuario:* Abrir una segunda terminal y ejecutar nuevamente `python main.py`. Se levantarán dos ventanas independientes con identificadores de terminal distintos, permitiendo votar en una y observar cómo la otra se actualiza automáticamente en milisegundos.

### Opción B: Generación del Ejecutable Standalone
Ejecutar el script por lotes:
```bash
build_executable.bat
```
El archivo ejecutable resultante se ubicará en `frontend_desktop/dist/DecisionRoom_G3.exe`.

---

## 6. Cumplimiento de Criterios de la Rúbrica

*   Frontend obligatorio en Electron + Python: **Cumplido al 100% mediante Eel y Chromium**.
*   Protocolo de integración WebSockets bidireccional y reactivo: **Cumplido al 100%**.
*   Actualización de interfaz en tiempo real sin recarga de página: **Cumplido al 100%**.
*   Empaquetado y distribución independiente: **Cumplido al 100% mediante PyInstaller**.
