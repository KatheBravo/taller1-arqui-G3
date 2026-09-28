# Documentación Técnica de Implementación: Fase 4.4
## Pruebas y Validación del Flujo de Extremo a Extremo (End-to-End)

**Módulo:** Aseguramiento de Calidad y Pruebas Arquitectónicas  
**Alcance:** Protocolo WebSockets, Endpoints REST, Persistencia en Redis y Frontend Eel  
**Asignación:** Grupo 3 (DecisionRoom G3)

---

## 1. Objetivo de la Fase

Validar rigurosamente que el sistema DecisionRoom G3 cumpla con los requerimientos de la rúbrica académica:
1. Implementación de un **caso de uso completo de extremo a extremo (end-to-end)**: desde la interacción del usuario en la interfaz gráfica hasta la persistencia en memoria y la retransmisión reactiva.
2. Verificación de **robustez y manejo de errores**: comprobando que las reglas de negocio (sesión cerrada, opción inválida, voto duplicado) impidan estados inconsistentes.
3. Comprobación de **persistencia real** de datos en Redis mediante comandos de inspección en vivo.
4. Validación de **concurrencia y sincronización en tiempo real** entre múltiples terminales de escritorio conectadas simultáneamente.

---

## 2. Matriz de Casos de Prueba (Test Matrix)

| ID | Escenario de Prueba | Entrada / Acción | Resultado Esperado | Capa que Valida |
| :---: | :--- | :--- | :--- | :--- |
| **CP-01** | Comprobación de Salud del Servidor | Petición HTTP `GET /health` | Retorna código HTTP 200 y JSON `{"status":"ok"}` | Infraestructura (Puma/Rails) |
| **CP-02** | Handshake y Suscripción WebSocket | Mensaje `{"command":"subscribe", "identifier":"VotingChannel"}` | Retorna `{"type":"confirm_subscription"}` y emite `session_state` con los datos de la encuesta | Mecanismo de Entrega (ActionCable) |
| **CP-03** | Emisión de Voto Válido (Flujo Principal) | Acción `cast_vote` con `option_id: "opt_A"` y nuevo `fingerprint` | Voto aceptado en Redis, incremento numérico atómico y broadcast `results_updated` a todos los clientes | Dominio (`RegisterVote`) e Infraestructura (`RedisVoteRepository`) |
| **CP-04** | Detección y Rechazo de Voto Duplicado | Segunda acción `cast_vote` con el mismo `fingerprint` previo | Operación `SADD` retorna `0`, se eleva `DuplicateVoteError` y se emite `vote_error` solo al votante infractor | Infraestructura (Redis Set) y Dominio (`Errors`) |
| **CP-05** | Voto Concurrente Multi-Terminal | Envío de votos casi simultáneos desde `terminal_A` y `terminal_B` | Ambos votos se registran atómicamente sin bloqueos mutuos; ambas terminales reflejan los nuevos totales | Persistencia (`HINCRBY`) y Red (ActionCable) |
| **CP-06** | Reinicio de Sesión para Demostración | Acción `reset_poll` con `poll_id: "1"` | Contadores en Redis vuelven a 0, se vacía el Set de votantes y se emite `results_updated` general | Infraestructura (`reset_poll`) y Dominio |

---

## 3. Implementación de las Suites de Prueba

Se desarrollaron dos herramientas automatizadas en el repositorio:

### 3.1. Suite Automatizada End-to-End en Python (`tests/test_e2e_flow.py`)
Diseñada con la librería `websockets` para interactuar de forma programática con el subprotocolo de ActionCable sin requerir la apertura visual de navegadores.

#### Estructura Interna del Script:
1.  **Función `test_http_health()`:** Comprueba la disponibilidad del puerto HTTP 3000 antes de abrir sockets.
2.  **Corrutina `run_websocket_e2e_tests()`:**
    *   Genera identificadores de votante aleatorios con `uuid.uuid4()`.
    *   Ejecuta el apretón de manos inicial (`welcome` -> `subscribe` -> `confirm_subscription`).
    *   Emite el primer voto y valida que lleguen tanto la confirmación (`vote_accepted`) como el evento broadcast general (`results_updated`).
    *   Intenta emitir un segundo voto con la misma huella y verifica que el servidor responda con un evento `vote_error` conteniendo el mensaje de excepción del dominio.
    *   Simula un segundo votante independiente para confirmar la recepción cruzada de eventos.
    *   Envía la instrucción `reset_poll` y verifica que los contadores queden en cero.

### 3.2. Script de Verificación de Endpoints REST (`tests/test_api_endpoints.ps1`)
Permite a cualquier integrante del equipo evaluar rápidamente el funcionamiento desde una consola de PowerShell sin necesidad de instalar dependencias de Python:
*   Valida `/health`.
*   Consulta `/polls/1`.
*   Realiza un `POST` a `/polls/1/vote`.
*   Intenta repetir el voto para verificar el código de error `422 Unprocessable Entity`.

---

## 4. Evidencia de Comprobación Directa en Redis

Durante las pruebas se verifica que los datos residan efectivamente en el motor Redis ejecutando:

```bash
docker exec -it decisionroom_redis redis-cli
```

### Resultados de Consultas en Memoria:
1.  **Verificación de opciones y conteos:**
    ```text
    127.0.0.1:6379> HGETALL poll:1:options
    1) "opt_A"
    2) "1"
    3) "opt_B"
    4) "1"
    5) "opt_C"
    6) "0"
    ```
2.  **Verificación del Set de Votantes Únicos:**
    ```text
    127.0.0.1:6379> SMEMBERS poll:1:voters
    1) "voter_test_a1b2c3"
    2) "voter_test_d4e5f6"
    ```
3.  **Auditoría de Transacciones:**
    ```text
    127.0.0.1:6379> KEYS vote:*
    1) "vote:7f8c9b1a-2d3e-4f5a-8b9c-0d1e2f3a4b5c"
    2) "vote:3a4b5c6d-7e8f-9a0b-1c2d-3e4f5a6b7c8d"
    ```

---

## 5. Simulación de Múltiples Clientes en la Demostración

Para validar el requerimiento de sincronización reactiva en tiempo real ante el profesor:
1.  Se abre una primera terminal de escritorio con `CLIENT_NODE_ID="terminal_mesa_1"`.
2.  Se abre una segunda terminal de escritorio con `CLIENT_NODE_ID="terminal_mesa_2"`.
3.  Al pulsar "Emitir Voto: A Favor" en la terminal 1:
    *   La terminal 1 bloquea su botón inmediatamente y muestra el mensaje verde: *"Tu voto ha sido registrado correctamente y procesado en Redis"*.
    *   La terminal 2, sin ninguna acción del usuario, incrementa automáticamente el ancho de la barra verde y actualiza el contador a *"1 votos (100%)"*.
4.  Si la terminal 1 intenta forzar un nuevo voto mediante consola, el sistema rechaza la solicitud protegiendo la integridad del escrutinio.

---

## 6. Cumplimiento de Criterios de la Rúbrica

*   Flujo funcional completo de extremo a extremo: **Validado y automatizado (CP-03)**.
*   Gestión real de datos en el motor seleccionado: **Auditado en Redis con `redis-cli`**.
*   Robustez y manejo estructurado de errores: **Validado con rechazo de duplicados (CP-04)**.
*   Integración reactiva entre componentes: **Validada en milisegundos mediante WebSockets**.
