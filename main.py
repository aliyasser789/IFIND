import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
sys.path.insert(0, BACKEND_DIR)

# Explicitly load .env from backend/ so JWT_SECRET and email vars are available
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(BACKEND_DIR) / ".env")

from app.DB_handeling.base import Base
from app.DB_handeling.engine import engine

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.auth import router as auth_router, user_router
from app.routers.items import router as items_router

app = FastAPI(title="IFind API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(auth_router)
app.include_router(user_router)
app.include_router(items_router)

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "IFind backend is running"}

print("IFind Backend Started")