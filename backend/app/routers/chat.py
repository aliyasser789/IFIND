import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.models.found_item import FoundItem
from app.models.user import User
from app.services.auth_service import get_current_user
from app.services.chat_service import (
    get_chat_history,
    get_user_chats,
    save_message,
    soft_delete_chat,
    start_chat,
)

router = APIRouter(prefix="/chat", tags=["chat"])

# In-memory connection manager: chat_id (str) → list of active WebSocket connections
_rooms: dict[str, list[WebSocket]] = {}


class StartChatRequest(BaseModel):
    item_id: uuid.UUID
    finder_id: uuid.UUID
    claimer_id: uuid.UUID


@router.post("/start", status_code=status.HTTP_200_OK)
def start_chat_endpoint(body: StartChatRequest, db: Session = Depends(get_db)):
    try:
        chat = start_chat(
            db=db,
            item_id=body.item_id,
            finder_id=body.finder_id,
            claimer_id=body.claimer_id,
        )
        return {"chat_id": chat.id}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/history/{chat_id}", status_code=status.HTTP_200_OK)
def chat_history(chat_id: uuid.UUID, db: Session = Depends(get_db)):
    return get_chat_history(db=db, chat_id=chat_id)


@router.get("/list", status_code=status.HTTP_200_OK)
def list_chats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    chats = get_user_chats(db=db, user_id=current_user.id)
    result = []
    for chat, other_user_username, message_count in chats:
        item = db.query(FoundItem).filter(FoundItem.id == chat.item_id).first()

        item_name = "Unknown Item"
        item_category = None
        item_photo_url = None
        district = None

        if item:
            item_category = item.category
            district = item.district

            if item.photo_url and len(item.photo_url) > 0:
                item_photo_url = item.photo_url[0]

            description = None
            if item.features and isinstance(item.features, dict):
                description = item.features.get("description") or None

            if description:
                item_name = description
            elif item_category:
                item_name = item_category

        result.append(
            {
                "id": chat.id,
                "item_id": chat.item_id,
                "finder_id": chat.finder_id,
                "claimer_id": chat.claimer_id,
                "created_at": chat.created_at,
                "item_name": item_name,
                "item_category": item_category,
                "item_photo_url": item_photo_url,
                "district": district,
                "item_features": item.features if item else {},
                "item_created_at": item.created_at.isoformat() if item and item.created_at else None,
                "other_user_username": other_user_username,
                "message_count": message_count,
            }
        )
    return result


@router.delete("/{chat_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_chat_endpoint(
    chat_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        deleted = soft_delete_chat(db=db, chat_id=chat_id, user_id=current_user.id)
    except ValueError:
        deleted = False
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat not found or access denied",
        )


@router.websocket("/ws/{chat_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    chat_id: str,
    sender_id: str,
    db: Session = Depends(get_db),
):
    await websocket.accept()

    room = _rooms.setdefault(chat_id, [])
    room.append(websocket)

    try:
        while True:
            data = await websocket.receive_text()

            msg = save_message(
                db=db,
                chat_id=uuid.UUID(chat_id),
                sender_id=uuid.UUID(sender_id),
                content=data,
            )

            payload = json.dumps(
                {
                    "id": str(msg["id"]),
                    "chat_id": str(msg["chat_id"]),
                    "sender_label": msg["sender_label"],
                    "content": msg["content"],
                    "sent_at": msg["sent_at"].isoformat(),
                }
            )

            for connection in list(room):
                await connection.send_text(payload)

    except WebSocketDisconnect:
        room.remove(websocket)
        if not room:
            del _rooms[chat_id]
