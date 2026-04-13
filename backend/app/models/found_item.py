import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.DB_handeling.base import Base


class FoundItem(Base):
    __tablename__ = "found_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    photo_url: Mapped[list | None] = mapped_column(JSONB, nullable=True)  # list of photo paths
    category: Mapped[str | None] = mapped_column(String(100), nullable=True)
    features: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    district: Mapped[str | None] = mapped_column(
        String(100), default="Unknown", nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
