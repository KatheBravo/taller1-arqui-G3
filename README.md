# DecisionRoom G3 - Sistema de Votación y Toma de Decisiones en Tiempo Real

Proyecto Académico para la asignatura de Arquitectura de Software (Taller 1 / Presentación 1).

## Descripción del Sistema
DecisionRoom G3 es una plataforma distribuida diseñada para salas de juntas, asambleas de socios y comités técnicos. Permite a múltiples delegados conectados desde sus estaciones de trabajo emitir votos en tiempo real sobre mociones y visualizar la actualización inmediata de resultados y gráficas mediante un canal bidireccional de WebSockets.

El sistema fue diseñado e implementado siguiendo estrictamente los principios de Clean Architecture, asegurando que la lógica de negocio permanezca completamente aislada de los frameworks de entrega y los motores de persistencia.

---

## Tecnologías Usadas
*   Estilo Arquitectónico: Clean Architecture (Arquitectura Limpia).
*   Frontend: Aplicación de Escritorio con Electron + Python (Eel).
*   Backend: Ruby on Rails (Ruby 3.2, configurado en modo API pura sin ActiveRecord).
*   Persistencia: Redis 7.x (Almacenamiento en memoria para conteos atómicos y control de votantes).
*   Protocolo de Integración: WebSockets (Bidireccional en tiempo real con ActionCable).
*   Contenerización: Docker y Docker Compose (Despliegue unificado de backend y base de datos).

---

## Pasos para Despliegue y Ejecución

### Prerrequisitos
*   Docker Desktop o Podman instalado y en ejecución.
*   Python 3.10+ instalado localmente para el cliente de escritorio.

### 1. Levantar la Infraestructura (Backend + Redis)
Desde la raíz del repositorio, ejecuta:
```bash
docker compose up --build
```
Esto levantará:
*   Redis en el puerto 6379.
*   Rails API y ActionCable WebSocket Server en el puerto 3000.

### 2. Ejecutar el Cliente de Escritorio (Electron + Python)
En una nueva terminal:
```bash
cd frontend_desktop
python -m venv venv

# En Windows:
venv\Scripts\activate
# En Linux/macOS:
# source venv/bin/activate

pip install -r requirements.txt
python main.py
```

Nota de prueba: Es posible abrir dos o más instancias de la aplicación de escritorio simultáneamente para simular varios miembros de la asamblea votando y verificando cómo las gráficas se actualizan en vivo en todas las pantallas.

---

## Documentación Técnica y Wiki Oficial
* **Wiki Oficial del Proyecto en GitHub:** [https://github.com/KatheBravo/taller1-arqui-G3/wiki](https://github.com/KatheBravo/taller1-arqui-G3/wiki) (Documentación exhaustiva de cada archivo de código, capas de Clean Architecture, infraestructura y pruebas).
* Documento de Arquitectura y Diseño: [docs/documentacion_tecnica/Documento_Tecnico_G3.md](docs/documentacion_tecnica/Documento_Tecnico_G3.md)
* Referencias a la Documentación Oficial: [docs/documentacion_tecnica/Referencias_Documentacion_Oficial.md](docs/documentacion_tecnica/Referencias_Documentacion_Oficial.md)
