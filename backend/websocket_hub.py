"""
AURA Backend — WebSocket Hub
Real-time updates for dashboard, alerts, and device status
"""
import json
from datetime import datetime
from typing import Dict, Set

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from auth import verify_token

router = APIRouter()


class ConnectionManager:
    """Manages WebSocket connections per user."""

    def __init__(self):
        self._connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self._connections:
            self._connections[user_id] = set()
        self._connections[user_id].add(websocket)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self._connections:
            self._connections[user_id].discard(websocket)
            if not self._connections[user_id]:
                del self._connections[user_id]

    async def send_to_user(self, user_id: str, message: dict):
        if user_id in self._connections:
            data = json.dumps(message, default=str)
            dead = set()
            for ws in self._connections[user_id]:
                try:
                    await ws.send_text(data)
                except Exception:
                    dead.add(ws)
            for ws in dead:
                self._connections[user_id].discard(ws)

    async def broadcast(self, message: dict):
        data = json.dumps(message, default=str)
        for user_id in list(self._connections.keys()):
            dead = set()
            for ws in self._connections[user_id]:
                try:
                    await ws.send_text(data)
                except Exception:
                    dead.add(ws)
            for ws in dead:
                self._connections[user_id].discard(ws)

    @property
    def active_connections(self) -> int:
        return sum(len(conns) for conns in self._connections.values())

    @property
    def active_users(self) -> int:
        return len(self._connections)


manager = ConnectionManager()


@router.websocket("/ws/{token}")
async def websocket_endpoint(websocket: WebSocket, token: str):
    user_id = verify_token(token)
    if not user_id:
        await websocket.close(code=1008)
        return

    await manager.connect(user_id, websocket)
    try:
        # Send initial connection message
        await websocket.send_json({
            "type": "connected",
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat(),
        })

        while True:
            # Receive messages from client (sensor data, etc.)
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                msg_type = message.get("type")

                if msg_type == "sensor_data":
                    # Broadcast to any admin dashboards monitoring this user
                    await manager.send_to_user(f"admin_{user_id}", {
                        "type": "user_sensor_update",
                        "user_id": user_id,
                        "data": message.get("data"),
                        "timestamp": datetime.utcnow().isoformat(),
                    })

                elif msg_type == "alert":
                    await manager.send_to_user(user_id, {
                        "type": "alert_update",
                        "alert": message.get("alert"),
                        "timestamp": datetime.utcnow().isoformat(),
                    })

                elif msg_type == "ping":
                    await websocket.send_json({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat(),
                    })

            except json.JSONDecodeError:
                pass

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)


# Admin endpoint for monitoring dashboard
@router.websocket("/ws/admin/{admin_id}")
async def admin_websocket(websocket: WebSocket, admin_id: str):
    await manager.connect(f"admin_{admin_id}", websocket)
    try:
        await websocket.send_json({
            "type": "admin_connected",
            "active_users": manager.active_users,
            "active_connections": manager.active_connections,
        })

        while True:
            data = await websocket.receive_text()
            # Admin can request user status etc.

    except WebSocketDisconnect:
        manager.disconnect(f"admin_{admin_id}", websocket)
