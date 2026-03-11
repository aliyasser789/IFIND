from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


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

    hashed_password = pwd_context.hash(password)

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
