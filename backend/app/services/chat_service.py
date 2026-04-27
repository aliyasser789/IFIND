import uuid

from sqlalchemy.orm import Session

from app.models.chat import Chat
from app.models.message import Message


def _anonymous_label(user_id: uuid.UUID) -> str:
    """Return a privacy-safe display label derived from the first 4 hex chars of the UUID."""
    return "User " + str(user_id)[:4]


def start_chat(
    db: Session,
    item_id: uuid.UUID,
    finder_id: uuid.UUID,
    claimer_id: uuid.UUID,
) -> Chat:
    existing = (
        db.query(Chat)
        .filter(Chat.item_id == item_id, Chat.claimer_id == claimer_id)
        .first()
    )
    if existing:
        return existing

    chat = Chat(
        item_id=item_id,
        finder_id=finder_id,
        claimer_id=claimer_id,
    )
    db.add(chat)
    db.commit()
    db.refresh(chat)
    return chat


def get_chat_history(db: Session, chat_id: uuid.UUID) -> list[dict]:
    messages = (
        db.query(Message)
        .filter(Message.chat_id == chat_id)
        .order_by(Message.sent_at.asc())
        .all()
    )
    return [
        {
            "id": msg.id,
            "chat_id": msg.chat_id,
            "sender_label": _anonymous_label(msg.sender_id),
            "content": msg.content,
            "sent_at": msg.sent_at,
        }
        for msg in messages
    ]


def get_user_chats(db: Session, user_id: uuid.UUID) -> list[tuple]:
    from sqlalchemy import and_, or_
    from sqlalchemy.orm import aliased
    from app.models.user import User

    FinderUser = aliased(User)
    ClaimerUser = aliased(User)

    rows = (
        db.query(Chat, FinderUser.username, ClaimerUser.username)
        .join(FinderUser, Chat.finder_id == FinderUser.id)
        .join(ClaimerUser, Chat.claimer_id == ClaimerUser.id)
        .filter(
            or_(
                and_(Chat.finder_id == user_id, Chat.deleted_by_finder == False),
                and_(Chat.claimer_id == user_id, Chat.deleted_by_claimer == False),
            )
        )
        .filter(
            db.query(Message).filter(Message.chat_id == Chat.id).exists()
        )
        .order_by(Chat.created_at.desc())
        .all()
    )

    result = []
    for chat, finder_username, claimer_username in rows:
        other_user_username = claimer_username if chat.finder_id == user_id else finder_username
        message_count = db.query(Message).filter(Message.chat_id == chat.id).count()
        result.append((chat, other_user_username, message_count))
    return bubble_sort_by_message_count(result)


def bubble_sort_by_message_count(chats: list[tuple]) -> list[tuple]:
    result = list(chats)
    n = len(result)
    for pass_index in range(n - 1):
        for i in range(n - 1 - pass_index):
            if result[i][2] < result[i + 1][2]:
                result[i], result[i + 1] = result[i + 1], result[i]
    return result


def soft_delete_chat(db: Session, chat_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise ValueError("Chat not found")
    if user_id == chat.finder_id:
        chat.deleted_by_finder = True
    elif user_id == chat.claimer_id:
        chat.deleted_by_claimer = True
    else:
        return False
    db.commit()
    return True


def save_message(
    db: Session,
    chat_id: uuid.UUID,
    sender_id: uuid.UUID,
    content: str,
) -> dict:
    message = Message(
        chat_id=chat_id,
        sender_id=sender_id,
        content=content,
    )
    db.add(message)
    db.commit()
    db.refresh(message)

    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if chat:
        if sender_id == chat.finder_id:
            chat.deleted_by_claimer = False
        elif sender_id == chat.claimer_id:
            chat.deleted_by_finder = False
        db.commit()

    return {
        "id": message.id,
        "chat_id": message.chat_id,
        "sender_label": _anonymous_label(message.sender_id),
        "content": message.content,
        "sent_at": message.sent_at,
    }
