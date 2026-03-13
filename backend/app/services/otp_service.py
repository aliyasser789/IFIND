from datetime import datetime, timedelta

_otp_store: dict = {}

OTP_EXPIRY_MINUTES = 10


def save_otp(email: str, code: str) -> None:
    _otp_store[email] = {
        "code": code,
        "expires_at": datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES),
    }


def verify_otp(email: str, code: str) -> bool:
    entry = _otp_store.get(email)
    if not entry:
        return False
    if entry["code"] != code:
        return False
    if datetime.utcnow() > entry["expires_at"]:
        return False
    return True


def delete_otp(email: str) -> None:
    _otp_store.pop(email, None)
