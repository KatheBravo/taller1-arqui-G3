import asyncio
import json
import sys
import uuid
import urllib.request
import websockets

BACKEND_HTTP_URL = "http://127.0.0.1:3000"
BACKEND_WS_URL = "ws://127.0.0.1:3000/cable"
CHANNEL_ID = json.dumps({"channel": "VotingChannel"})


def test_http_health():
    print("[TEST 1] Verificando salud del servidor Rails (/health)...")
    try:
        with urllib.request.urlopen(f"{BACKEND_HTTP_URL}/health", timeout=5) as response:
            assert response.status == 200
            data = json.loads(response.read().decode("utf-8"))
            assert data.get("status") == "ok"
            print(" -> PASS: Servidor Rails activo y respondiendo 200 OK.")
            return True
    except Exception as e:
        print(f" -> FAIL: No se pudo conectar al backend HTTP: {e}")
        return False


async def run_websocket_e2e_tests():
    print("\n[TEST 2] Estableciendo conexion WebSocket y handshake con ActionCable...")

    test_voter_1 = f"voter_test_{uuid.uuid4().hex[:6]}"
    test_voter_2 = f"voter_test_{uuid.uuid4().hex[:6]}"

    async with websockets.connect(BACKEND_WS_URL) as ws:
        # Handshake: Mensaje de bienvenida
        welcome = json.loads(await ws.recv())
        assert welcome.get("type") == "welcome", "Fallo handshake: se esperaba 'welcome'"
        print(" -> PASS: Handshake 'welcome' recibido de ActionCable.")

        # Suscripcion al canal de votacion
        subscribe_cmd = {
            "command": "subscribe",
            "identifier": CHANNEL_ID
        }
        await ws.send(json.dumps(subscribe_cmd))

        # Esperar confirmacion
        confirmed = False
        initial_state = None
        for _ in range(3):
            msg = json.loads(await ws.recv())
            if msg.get("type") == "confirm_subscription":
                confirmed = True
                print(" -> PASS: Suscripcion confirmada a 'VotingChannel'.")
            elif msg.get("message", {}).get("event") == "session_state":
                initial_state = msg["message"]["data"]
                print(f" -> PASS: Estado inicial recibido: '{initial_state['poll']['title']}'")

        assert confirmed, "No se recibio confirmacion de suscripcion."

        # TEST 3: Emision de voto valido para Votante 1
        print(f"\n[TEST 3] Emitiendo voto valido (Votante: {test_voter_1}, Opcion: 'opt_A')...")
        vote_payload = {
            "command": "message",
            "identifier": CHANNEL_ID,
            "data": json.dumps({
                "action": "cast_vote",
                "poll_id": "1",
                "option_id": "opt_A",
                "fingerprint": test_voter_1
            })
        }
        await ws.send(json.dumps(vote_payload))

        vote_accepted = False
        results_received = False

        while not (vote_accepted and results_received):
            msg = json.loads(await ws.recv())
            if msg.get("type") == "ping":
                continue
            payload = msg.get("message", {})
            event = payload.get("event")

            if event == "vote_accepted":
                vote_accepted = True
                print(" -> PASS: Evento 'vote_accepted' confirmado.")
            elif event == "results_updated":
                results_received = True
                totals = payload.get("totals", {})
                print(f" -> PASS: Evento 'results_updated' recibido en tiempo real. Totales: {totals}")

        # TEST 4: Intento de voto duplicado con el mismo Votante 1 (Debe fallar)
        print(f"\n[TEST 4] Probando validacion de voto duplicado (Votante: {test_voter_1}, Opcion: 'opt_B')...")
        duplicate_payload = {
            "command": "message",
            "identifier": CHANNEL_ID,
            "data": json.dumps({
                "action": "cast_vote",
                "poll_id": "1",
                "option_id": "opt_B",
                "fingerprint": test_voter_1
            })
        }
        await ws.send(json.dumps(duplicate_payload))

        duplicate_rejected = False
        for _ in range(5):
            msg = json.loads(await ws.recv())
            if msg.get("type") == "ping":
                continue
            payload = msg.get("message", {})
            if payload.get("event") == "vote_error":
                duplicate_rejected = True
                error_msg = payload.get("message")
                print(f" -> PASS: Voto duplicado rechazado correctamente por Redis/Dominio: '{error_msg}'")
                break

        assert duplicate_rejected, "Fallo: el sistema permitio emitir dos votos al mismo identificador."

        # TEST 5: Voto concurrente con Votante 2 (Diferente terminal)
        print(f"\n[TEST 5] Emitiendo voto desde segunda terminal independiente (Votante: {test_voter_2}, Opcion: 'opt_B')...")
        vote_2_payload = {
            "command": "message",
            "identifier": CHANNEL_ID,
            "data": json.dumps({
                "action": "cast_vote",
                "poll_id": "1",
                "option_id": "opt_B",
                "fingerprint": test_voter_2
            })
        }
        await ws.send(json.dumps(vote_2_payload))

        voter_2_accepted = False
        while not voter_2_accepted:
            msg = json.loads(await ws.recv())
            if msg.get("type") == "ping":
                continue
            payload = msg.get("message", {})
            if payload.get("event") == "vote_accepted":
                voter_2_accepted = True
                print(" -> PASS: Voto de segunda terminal aceptado exitosamente.")

        # TEST 6: Reinicio de sesion (Reset para demostracion)
        print("\n[TEST 6] Solicitando reinicio de la votacion (/reset)...")
        reset_cmd = {
            "command": "message",
            "identifier": CHANNEL_ID,
            "data": json.dumps({
                "action": "reset_poll",
                "poll_id": "1"
            })
        }
        await ws.send(json.dumps(reset_cmd))

        reset_confirmed = False
        for _ in range(5):
            msg = json.loads(await ws.recv())
            if msg.get("type") == "ping":
                continue
            payload = msg.get("message", {})
            if payload.get("event") == "results_updated":
                totals = payload.get("totals", {})
                if all(v == 0 for v in totals.values()):
                    reset_confirmed = True
                    print(f" -> PASS: Votacion reiniciada a cero correctamente: {totals}")
                    break

        assert reset_confirmed, "Fallo al verificar contadores reiniciados en cero."


def main():
    print("================================================================")
    print(" DecisionRoom G3: Suite de Pruebas de Flujo End-to-End")
    print("================================================================")

    if not test_http_health():
        print("\n[AVISO] El servidor backend no esta respondiendo en http://127.0.0.1:3000.")
        print("Asegurate de iniciar Docker Compose antes de ejecutar esta suite:")
        print("  docker compose up --build")
        sys.exit(1)

    try:
        asyncio.run(run_websocket_e2e_tests())
        print("\n================================================================")
        print(" RESULTADO FINAL: TODOS LOS CASOS DE PRUEBA PASARON EXITOSAMENTE")
        print("================================================================")
    except Exception as e:
        print(f"\n[ERROR] Fallo en la ejecucion de pruebas: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
