from dotenv import load_dotenv
import os
from pathlib import Path

# Resolve .env relative to this file: backend/app/DB_handeling/config.py -> backend/.env
env_path = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(dotenv_path=env_path)

DATABASE_URL = os.getenv("DATABASE_URL")
