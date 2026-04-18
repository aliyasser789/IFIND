import uuid

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.models.report import Report
from app.models.user import User
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/reports", tags=["reports"])


class ReportSubmitRequest(BaseModel):
    chat_id: uuid.UUID
    reported_id: uuid.UUID
    reasons: list[str]
    description: str | None = None


@router.post("/submit", status_code=status.HTTP_201_CREATED)
def submit_report(
    body: ReportSubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    report = Report(
        reporter_id=current_user.id,
        reported_id=body.reported_id,
        chat_id=body.chat_id,
        reasons=body.reasons,
        description=body.description,
        status="pending",
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return {"id": str(report.id), "status": report.status}
