from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.models.user import User
from app.services.auth_service import (
    confirm_verification_code,
    create_access_token,
    get_current_user,
    register_user,
    send_verification_code,
)
from app.services.id_verify_service import verify_id_card

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
    confirm_verification_code(db=db, email=body.email, code=body.code)
    return {"message": "Email verified successfully"}


@router.post("/verify-id", status_code=status.HTTP_200_OK)
async def verify_id(
    email: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """
    Upload one ID card image (JPEG/PNG).
    Requires the user's verified email as a form field (no JWT yet at this stage).
    On success, marks the user as id_verified, saves their national ID number,
    and returns a JWT token — the first token issued in the registration flow.
    """
    user = db.query(User).filter(User.email == email).first()
    if not user or not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email not verified",
        )

    image_bytes = await file.read()
    result = verify_id_card(image_bytes)

    if result.get("verified"):
        user.id_verified = True
        user.national_id_num = result["national_id"]
        user.id_image_front = file.filename
        db.commit()
        token = create_access_token(user_id=str(user.id))
        return {**result, "access_token": token, "token_type": "bearer"}

    return result


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/login", status_code=status.HTTP_200_OK)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    from app.services.auth_service import verify_password
    user = db.query(User).filter(User.email == body.email).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not user.email_verified or not user.id_verified:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Please complete your registration first")
    token = create_access_token(user_id=str(user.id))
    return {"access_token": token, "token_type": "bearer"}


@router.post("/upload-id-back", status_code=status.HTTP_200_OK)
async def upload_id_back(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Upload the back of an ID card image (JPEG/PNG).
    Requires a valid Bearer JWT token.
    Saves the filename to id_image_back for the authenticated user.
    """
    current_user.id_image_back = file.filename
    db.commit()
    return {"message": "ID back photo saved successfully"}
