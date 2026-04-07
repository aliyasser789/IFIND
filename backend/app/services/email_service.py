import os
import smtplib

from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())


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


def send_reset_email(to_email: str, code: str) -> None:
    smtp_login = os.getenv("EMAIL_ADDRESS")
    password = os.getenv("EMAIL_PASSWORD")
    sender_from = os.getenv("EMAIL_FROM")

    from email.mime.text import MIMEText

    subject = "iFind - Password Reset Code"
    body = (
        f"Your iFind password reset code is: {code}\n\n"
        "This code expires in 10 minutes.\n\n"
        "If you did not request a password reset, please ignore this email."
    )
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