import os
import smtplib

from dotenv import load_dotenv

_ENV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".env")
load_dotenv(_ENV_PATH)


def send_verification_email(to_email: str, code: str) -> None:
    smtp_login = os.getenv("EMAIL_ADDRESS")
    password = os.getenv("EMAIL_PASSWORD")
    sender_from = os.getenv("EMAIL_FROM")

    from email.mime.text import MIMEText

    subject = "IFind - Your Email Verification Code"
    body = f"Your IFind verification code is: {code}\n\nThis code expires in 10 minutes."
    message = MIMEText(body, "plain", "utf-8")
    message["Subject"] = subject
    message["From"] = sender_from
    message["To"] = to_email

    with smtplib.SMTP("smtp-relay.brevo.com", 587) as server:
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(smtp_login, password)
        server.sendmail(sender_from, to_email, message.as_string())


def send_reset_email(to_email: str, reset_link: str) -> None:
    # to be implemented later
    pass