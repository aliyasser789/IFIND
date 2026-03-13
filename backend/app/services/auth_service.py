import random

import bcrypt
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.services import email_service, otp_service


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


def register_user(
    db: Session,
    full_name: str,
    age: int,
    email: str,
    username: str,
    password: str,
    confirm_password: str,
) -> dict:
    if db.query(User).filter(User.email == email).first():
        raise ValueError("Email already registered")

    if db.query(User).filter(User.username == username).first():
        raise ValueError("Username already taken")

    if password != confirm_password:
        raise ValueError("Passwords do not match")

    hashed_password = hash_password(password)

    new_user = User(
        full_name=full_name,
        age=age,
        email=email,
        username=username,
        password_hash=hashed_password,
        email_verified=False,
        id_verified=False,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "Account created. Please verify your email."}


def send_verification_code(db: Session, email: str) -> dict:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise ValueError("No account found with that email")

    code = str(random.randint(100000, 999999))
    otp_service.save_otp(email, code)
    email_service.send_verification_email(email, code)

    return {"message": "Verification code sent to your email"}


def confirm_verification_code(db: Session, email: str, code: str) -> dict:
    if not otp_service.verify_otp(email, code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired code",
        )

    user = db.query(User).filter(User.email == email).first()
    user.email_verified = True
    db.commit()
    otp_service.delete_otp(email)

    return {"message": "Email verified successfully"}
