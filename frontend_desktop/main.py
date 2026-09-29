import asyncio
import json
import os
import sys
import threading
import urllib.request
import uuid
import eel
import websockets
from dotenv import load_dotenv

# Cargar configuraciones del entorno
load_dotenv()

WS_BACKEND_URL = os.getenv("WS_BACKEND_URL", "ws://127.0.0.1:3000/cable")
# Generar o asignar un ID unico de terminal para control de votos duplicados
CLIENT_NODE_ID = os.getenv("CLIENT_NODE_ID") or f"terminal_{uuid.uuid4().hex[:6]}"

CHANNEL_IDENTIFIER = json.dumps({"channel": "VotingChannel"})

# Cola asincrona para enviar mensajes hacia el socket desde Eel
outbound_queue = None
active_websocket = None
async_loop = None

# Inicializar Eel apuntando a la carpeta de interfaz web
web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")
eel.init(web_dir)


# 1. Bucle asincrono para el protocolo WebSocket de ActionCable

async def websocket_listener():
    global active_websocket, outbound_queue
    outbound_queue = asyncio.Queue()

    while True:
        try:
            print(f"[WebSocket] Conectando a {WS_BACKEND_URL}...")
            eel.set_connection_status(False, "Conectando al servidor Rails...")()

            async with websockets.connect(WS_BACKEND_URL) as ws:
                active_websocket = ws
                print("[WebSocket] Conexion TCP establecida. Esperando handshake de ActionCable...")

                # 1. Handshake inicial: recibir mensaje de bienvenida
                welcome_raw = await ws.recv()
                welcome_json = json.loads(welcome_raw)
                print(f"[WebSocket] Mensaje del servidor: {welcome_json.get('type')}")

                # 2. Suscribirse al VotingChannel
                subscribe_msg = {
                    "command": "subscribe",
                    "identifier": CHANNEL_IDENTIFIER
                }
                await ws.send(json.dumps(subscribe_msg))
                print(f"[WebSocket] Suscripcion enviada al canal: {CHANNEL_IDENTIFIER}")

                eel.set_connection_status(True, f"Conectado ({CLIENT_NODE_ID})", CLIENT_NODE_ID)()
                try:
                    eel.set_terminal_id(CLIENT_NODE_ID)()
                except Exception:
                    pass

                # Precargar estado inmediatamente para garantizar que la UI muestre la sesion activa
                try:
                    initial_data = fetch_initial_poll_data()
                    if initial_data:
                        eel.update_poll_state(initial_data)()
                except Exception:
                    pass

                # Tarea de envio concurrente
                async def sender_task():
                    while True:
                        payload = await outbound_queue.get()
                        await ws.send(json.dumps(payload))
                        outbound_queue.task_done()

                sender_coro = asyncio.create_task(sender_task())

                # 3. Bucle de lectura de eventos desde Rails
                while True:
                    raw_msg = await ws.recv()
                    data = json.loads(raw_msg)
                    msg_type = data.get("type")

                    # Tolerar o ignorar pings de salud
                    if msg_type == "ping":
                        continue

                    if msg_type == "confirm_subscription":
                        print("[WebSocket] Suscripcion confirmada por ActionCable.")
                        continue

                    # Mensajes emitidos por el canal de votacion
                    if "message" in data:
                        message_payload = data["message"]
                        event = message_payload.get("event")

                        print(f"[WebSocket] Evento recibido: {event}")

                        if event in ("session_state", "current_status"):
                            eel.update_poll_state(message_payload.get("data"))()

                        elif event == "results_updated":
                            eel.update_results(message_payload)()

                        elif event == "vote_accepted":
                            eel.on_vote_accepted(message_payload)()

                        elif event == "vote_error":
                            eel.on_vote_error(message_payload.get("message"))()

        except (websockets.exceptions.ConnectionClosed, ConnectionRefusedError, OSError) as e:
            print(f"[WebSocket] Desconectado del servidor: {e}. Reconectando en 3 segundos...")
            eel.set_connection_status(False, "Desconectado (Reintentando en 3s...)")()
            await asyncio.sleep(3)
        except Exception as e:
            print(f"[WebSocket] Error inesperado: {e}. Reintentando...")
            await asyncio.sleep(3)


def start_async_loop():
    global async_loop
    async_loop = asyncio.new_event_loop()
    asyncio.set_event_loop(async_loop)
    async_loop.run_until_complete(websocket_listener())


# 2. Funciones de Python expuestas a JavaScript via Eel

@eel.expose
def send_vote(poll_id, option_id):
    """Llamado desde la UI cuando el usuario hace clic en votar."""
    print(f"[Eel] Emitiendo voto: poll={poll_id}, option={option_id}, fingerprint={CLIENT_NODE_ID}")

    action_payload = {
        "command": "message",
        "identifier": CHANNEL_IDENTIFIER,
        "data": json.dumps({
            "action": "cast_vote",
            "poll_id": str(poll_id),
            "option_id": str(option_id),
            "fingerprint": CLIENT_NODE_ID
        })
    }

    if async_loop and outbound_queue:
        async_loop.call_soon_threadsafe(outbound_queue.put_nowait, action_payload)


@eel.expose
def reset_session(poll_id):
    """Llamado desde la UI para reiniciar contadores para demostracion."""
    print(f"[Eel] Solicitando reinicio de la votacion #{poll_id}")
    action_payload = {
        "command": "message",
        "identifier": CHANNEL_IDENTIFIER,
        "data": json.dumps({
            "action": "reset_poll",
            "poll_id": str(poll_id)
        })
    }

    if async_loop and outbound_queue:
        async_loop.call_soon_threadsafe(outbound_queue.put_nowait, action_payload)


def fetch_initial_poll_data():
    """Consulta directa a la API de Rails para precargar datos de inmediato."""
    try:
        http_url = WS_BACKEND_URL.replace("ws://", "http://").replace("wss://", "https://").replace("/cable", "/polls/1")
        req = urllib.request.Request(http_url, headers={"User-Agent": "DecisionRoomClient"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return data
    except Exception as e:
        print(f"[HTTP] Consulta inicial de votacion: {e}")
    return None


@eel.expose
def request_initial_state():
    """Solicitar estado inicial al cargar la pagina."""
    # 1. Enviar el identificador del terminal para actualizar el badge gris
    try:
        eel.set_terminal_id(CLIENT_NODE_ID)()
    except Exception:
        pass

    # 2. Precargar datos de la votacion inmediatamente via HTTP
    poll_data = fetch_initial_poll_data()
    if poll_data:
        try:
            eel.update_poll_state(poll_data)()
        except Exception:
            pass

    # 3. Solicitar sincronizacion a traves del canal WebSocket
    action_payload = {
        "command": "message",
        "identifier": CHANNEL_IDENTIFIER,
        "data": json.dumps({
            "action": "request_status",
            "poll_id": "1"
        })
    }

    if async_loop and outbound_queue:
        async_loop.call_soon_threadsafe(outbound_queue.put_nowait, action_payload)


# 3. Punto de entrada principal

if __name__ == "__main__":
    # Iniciar hilo en segundo plano para el bucle de WebSocket
    ws_thread = threading.Thread(target=start_async_loop, daemon=True)
    ws_thread.start()

    print("=======================================================")
    print(" DecisionRoom G3 - Terminal de Escritorio (Eel/Python)")
    print(f" ID del Terminal: {CLIENT_NODE_ID}")
    print(f" Servidor WebSocket: {WS_BACKEND_URL}")
    print("=======================================================")

    # Asignar puerto fijo y predecible: 8002 si es terminal B, 8001 para terminal A
    app_port = int(os.getenv("PORT") or (8002 if "B" in CLIENT_NODE_ID or "2" in CLIENT_NODE_ID else 8001))
    url = f"http://localhost:{app_port}/index.html"

    print("=======================================================")
    print(" DecisionRoom G3 - Terminal de Escritorio (Eel/Python)")
    print(f" ID del Terminal: {CLIENT_NODE_ID}")
    print(f" Servidor WebSocket: {WS_BACKEND_URL}")
    print(f" Interfaz web disponible en:")
    print(f" >>> {url} <<<")
    print("=======================================================")

    # Abrir automaticamente en el navegador de Ubuntu (Firefox o Chrome)
    import webbrowser
    def open_browser():
        try:
            webbrowser.open(url)
        except Exception:
            pass

    threading.Timer(1.0, open_browser).start()

    # Iniciar servidor Eel sin intentar invocar binarios externos incompatibles
    try:
        eel.start(
            "index.html",
            host="localhost",
            port=app_port,
            mode=False
        )
    except Exception as e:
        print(f"[Eel] Error al iniciar servidor: {e}")
