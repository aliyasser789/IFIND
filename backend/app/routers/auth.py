from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.services.auth_service import (
    confirm_verification_code,
    register_user,
    send_verification_code,
)

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterRequest(BaseModel):
    full_name: str
    age: int
    email: str
    username: str
    password: str
    confirm_password: str


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    try:
        result = register_user(
            db=db,
            full_name=body.full_name,
            age=body.age,
            email=body.email,
            username=body.username,
            password=body.password,
            confirm_password=body.confirm_password,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


class SendVerificationRequest(BaseModel):
    email: str


class VerifyEmailRequest(BaseModel):
    email: str
    code: str


@router.post("/send-verification", status_code=status.HTTP_200_OK)
def send_verification(body: SendVerificationRequest, db: Session = Depends(get_db)):
    try:
        result = send_verification_code(db=db, email=body.email)
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.post("/verify-email", status_code=status.HTTP_200_OK)
def verify_email(body: VerifyEmailRequest, db: Session = Depends(get_db)):
    result = confirm_verification_code(db=db, email=body.email, code=body.code)
    return result
